# Film Strip Frame Detection: Precise Boundary Algorithm

## Problem

Given a scanned film strip (TIFF/FIF, 135 format), cut individual frames with sub-pixel precision without modifying pixel values.

## Key Insight

Frame-to-frame gaps in film strips are **dark horizontal bands** ~20-120px wide, surrounded by much brighter frame content (~20000-30000 units of 16-bit luminance difference in raw scans). Don't use abstract gap-score signals for boundary detection — use the **raw luminance projection** to find the exact boundary of the dark band.

## Algorithm

### 1. Find Gap Centers (existing gap detection)

Use any peak-finding approach (gap_score, luminance dips, etc.) to find approximate gap center positions.

### 2. Find Precise Dark-Band Boundaries

For each gap:

```python
def find_precise_frame_boundaries(img_gray, gap_centers, orientation):
    """Given gap center positions, find exact frame boundaries using raw luminance."""
    if orientation == "horizontal":
        signal = img_gray.mean(axis=0)  # column-wise
    else:
        signal = img_gray.mean(axis=1)  # row-wise
    
    frames = []
    cuts = [0] + sorted(gap_centers) + [len(signal)]
    
    for i in range(len(cuts) - 1):
        raw_start, raw_end = cuts[i], cuts[i+1]
        
        # First frame: skip scanner border (pure white 65535)
        left_pos = raw_start
        if i == 0:
            for p in range(raw_start, min(raw_start + 200, raw_end - 5)):
                if abs(signal[p] - signal[p+5]) > (signal.max() - signal.min()) * 0.05:
                    continue  # still in scanner border (large fluctuation)
                left_pos = p
                break
        
        # Last frame: skip trailing scanner border
        right_pos = raw_end
        if i == len(cuts) - 2:
            for p in range(raw_end - 1, max(raw_start, raw_end - 200), -1):
                if abs(signal[p] - signal[p-5]) > (signal.max() - signal.min()) * 0.05:
                    continue
                right_pos = p + 1
                break
        
        # Middle frames: find where luminance recovers from dark band to frame content
        if i > 0 and i < len(cuts) - 2:
            gap = cuts[i]
            
            # Left edge: scan left from gap center, find where luminance rises to threshold
            left_vals = signal[max(0, gap-150):gap]
            if len(left_vals) > 10:
                valley = np.argmin(left_vals)
                valley_val = left_vals[valley]
                # Compare with frame content 100-300px away
                frame_vals = signal[max(0, gap-300):max(0, gap-100)]
                if len(frame_vals) > 10:
                    frame_val = np.median(frame_vals)
                    thresh = valley_val + (frame_val - valley_val) * 0.35  # 35% recovery
                    for p in range(max(0,gap-150) + valley, -1, -1):
                        if p >= len(signal): continue
                        if signal[p] >= thresh:
                            left_pos = p + 1
                            break
            
            # Right edge: scan right from gap center
            right_vals = signal[gap:min(len(signal), gap+150)]
            if len(right_vals) > 10:
                valley = np.argmin(right_vals)
                valley_val = right_vals[valley]
                frame_vals = signal[min(len(signal), gap+100):min(len(signal), gap+300)]
                if len(frame_vals) > 10:
                    frame_val = np.median(frame_vals)
                    thresh = valley_val + (frame_val - valley_val) * 0.35
                    for p in range(gap + valley, min(len(signal), gap+150)):
                        if signal[p] >= thresh:
                            right_pos = p - 1
                            break
        
        # Shrink by margin_ratio to avoid including any remaining dark edge
        margin = max(3, int((right_pos - left_pos) * 0.03))
        actual_start = left_pos + margin
        actual_end = right_pos - margin
        
        if actual_end - actual_start > 30:  # minimum viable frame
            frames.append((actual_start, actual_end))
    
    return frames
```

### 3. Fallback

If the luminance-threshold method fails to find enough frames (e.g. on synthetic test images with uniform brightness), fall back to simple equidistant splitting based on gap positions plus margin:

```python
cuts = [0] + gaps_sorted + [len(signal)]
for j in range(len(cuts) - 1):
    gap_width = cuts[j+1] - cuts[j]
    s = cuts[j] + int(gap_width * 0.03)
    e = cuts[j+1] - int(gap_width * 0.03)
    if e - s >= 30:
        frames.append((s, e))
```

## Validation

Always verify against raw pixel data:

```python
row_avg = gray.mean(axis=1)  # for vertical strips
left_frame = row_avg[max(0,gap-300):max(0,gap-100)].mean()
gap_dark = row_avg[gap].mean()  
right_frame = row_avg[min(len(row_avg),gap+100):min(len(row_avg),gap+300)].mean()
# A real gap should be ~50% darker than frame content
assert gap_dark < min(left_frame, right_frame) * 0.5
```

## Critical: Don't Modify Pixels

The frame boundary detection only determines *where* to cut. The actual cut operation must:

```python
# read original image → crop → write back — NO pixel touching
img = tifffile.imread(path)
cropped = img[y:y+h, x:x+w]
tifffile.imwrite(output_path, cropped)  # same dtype, same values
```

Do NOT convert color spaces, apply gamma, rescale dynamic range, or adjust white balance during the crop operation.
