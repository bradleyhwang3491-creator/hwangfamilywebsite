const MAX_BYTES = 5 * 1024 * 1024;
const MAX_DIMENSION = 2400;

function canvasToBlob(canvas: HTMLCanvasElement, quality: number): Promise<Blob | null> {
  return new Promise((resolve) => canvas.toBlob(resolve, 'image/jpeg', quality));
}

/** Resizes/compresses an image file to stay under maxBytes (default 5MB). Non-image files pass through unchanged. */
export async function resizeImageToLimit(file: File, maxBytes = MAX_BYTES): Promise<File> {
  if (!file.type.startsWith('image/') || file.size <= maxBytes) return file;

  const bitmap = await createImageBitmap(file);
  let width = bitmap.width;
  let height = bitmap.height;
  if (width > MAX_DIMENSION || height > MAX_DIMENSION) {
    const scale = MAX_DIMENSION / Math.max(width, height);
    width = Math.round(width * scale);
    height = Math.round(height * scale);
  }

  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  if (!ctx) return file;

  canvas.width = width;
  canvas.height = height;
  ctx.drawImage(bitmap, 0, 0, width, height);

  let quality = 0.9;
  let blob = await canvasToBlob(canvas, quality);

  while (blob && blob.size > maxBytes && quality > 0.3) {
    quality -= 0.1;
    blob = await canvasToBlob(canvas, quality);
  }

  while (blob && blob.size > maxBytes && width > 400) {
    width = Math.round(width * 0.85);
    height = Math.round(height * 0.85);
    canvas.width = width;
    canvas.height = height;
    ctx.drawImage(bitmap, 0, 0, width, height);
    blob = await canvasToBlob(canvas, quality);
  }

  if (!blob) return file;

  const newName = file.name.replace(/\.\w+$/, '') + '.jpg';
  return new File([blob], newName, { type: 'image/jpeg' });
}
