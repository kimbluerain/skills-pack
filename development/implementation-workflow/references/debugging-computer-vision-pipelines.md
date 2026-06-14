# Debugging Computer Vision Signal-Processing Pipelines

## Core Principle: Separate Signal from Algorithm

When a CV detection algorithm produces wrong results, **never trust the abstracted gap-score / confidence-map as ground truth** — check the raw pixel values directly. The signal-processing chain (blur, normalize, weight, combine) can create peaks where no physical feature exists and miss real features.

## Debugging Workflow

### 1. Validate Ground Truth First

```python
# Don't assume the detected "gap" is real — check pixel brightness
img = read_image(filename)
row_avg = img.mean(axis=(1,2) if img.ndim==3 else 1)

for g in detected_gaps:
    window = img[max(0,g-50):g+50]
    print(f'Gap {g}: brightness at gap={img[g].mean():.0f}, '
          f'min in window={window.min(axis=0).mean():.0f}')
# A real gap should be 30-50% DARKER than frame content
```

### 2. Compare False vs True Positives

```
TRUE gap @ 3591: brightness=13669  ← dark band between frames
TRUE gap @ 7023: brightness=13609  ← dark band between frames
FALSE gap @ 13426: brightness=29194 ← NOT a gap (inside frame)
```

If the brightness delta is 2× between false and true positives, the detection is a false positive.

### 3. Check Each Stage of the Pipeline

```python
# 1. Grayscale
gray = to_grayscale(img)

# 2. Crop/roi (does it exclude the feature?)
center = _crop_center_band(gray, 0.70)

# 3. Raw projection (before any smoothing)
proj = center.mean(axis=axis)

# 4. Smoothed signal (is the window too large?)
smoothed = median_filter(proj, size=window)
# Check: does a narrow gap vanish at larger window sizes?
for w in [11, 21, 51, 101, 201]:
    s = median_filter(proj, size=w)
    peaks = find_peaks(s, ...)
    print(f'Window {w}: {len(peaks)} peaks')
```

### 4. Fix the Bottleneck Stage

**Most common failure: smoothing kills narrow features.**
- Start with the smallest reasonable window and grow
- Validate that the window preserves features you can see in raw pixel data
- A median filter of size `N` removes features narrower than `N/2` pixels

### 5. Add Validation Gates

After detection, verify each candidate against raw pixel data:

```python
def _validate_gap(gap_pos, img, threshold=0.20):
    """Reject a candidate gap if it's not actually darker than frame content."""
    gap_brightness = img[gap_pos].mean()
    # Compare with surrounding frame regions
    left_frame = img[max(0,gap_pos-500):gap_pos-50].mean()
    right_frame = img[gap_pos+50:min(img.shape[0],gap_pos+500)].mean()
    frame_brightness = max(left_frame, right_frame)
    # Gap should be at least `threshold` fraction darker
    return gap_brightness < frame_brightness * (1 - threshold)
```

## Pitfalls

1. **ROI cropping hides the feature** — if you crop to center 70% to avoid sprocket holes, ensure the actual gap falls within the cropped region
2. **Weighted fusion amplifies noise** — three weak signals fused can produce a false peak that doesn't exist in any individual signal
3. **Smoothing and min_distance interact** — a large smoothing window followed by a large min_distance creates a "comb filter" that can miss every other gap
4. **DP cost functions prefer long chains** — when using dynamic programming to select candidate gaps, a false positive that extends a chain may be preferred over the correct position that creates a shorter chain
