from retinaface import RetinaFace
from deepface import DeepFace
from PIL import Image
import cv2
import sys
import os
import json

sys.stdout.reconfigure(line_buffering=True)

def detect_and_process_face(image_path):
    print(f"Processing image: {image_path}", flush=True)
    try:
        # Detect face using RetinaFace
        faces = RetinaFace.extract_faces(img_path=image_path, align=True)
        if not faces:
            print("No face detected! Skipping...", flush=True)
            return None, None

        # Select the first detected face
        face_np = faces[0]

        # Process face
        # Apply median blur
        face_np = cv2.medianBlur(face_np, 1)

        # Convert to YUV and equalize histogram for brightness
        face_yuv = cv2.cvtColor(face_np, cv2.COLOR_BGR2YUV)
        face_yuv[:, :, 0] = cv2.equalizeHist(face_yuv[:, :, 0])
        processed_face = cv2.cvtColor(face_yuv, cv2.COLOR_YUV2BGR)

        # Apply bilateral filter for smoothness
        processed_face = cv2.bilateralFilter(processed_face, 0, 0, 0)

        # Save original and processed face images
        original_output_path = os.path.join(os.path.dirname(image_path), 'original_cropped_face.jpg')
        processed_output_path = os.path.join(os.path.dirname(image_path), 'processed_face.jpg')
        Image.fromarray(face_np).save(original_output_path, 'JPEG')
        cv2.imwrite(processed_output_path, processed_face)

        print(f"Original face saved to: {original_output_path}", flush=True)
        print(f"Processed face saved to: {processed_output_path}", flush=True)

        return original_output_path, processed_output_path

    except Exception as e:
        print(f"Error processing image: {e}", flush=True)
        return None, None

def generate_embedding(image_path, model_name="GhostFaceNet"):
    try:
        # Generate embeddings using DeepFace
        embedding_objs = DeepFace.represent(
            img_path=image_path,
            model_name=model_name,
            detector_backend='retinaface',
            enforce_detection=True
        )
        return embedding_objs[0]["embedding"] if embedding_objs else None
    except Exception as e:
        print(f"Error generating embedding for {image_path}: {e}", flush=True)
        return None

# Main logic
if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python face_crop.py <image_path>", flush=True)
        sys.exit(1)

    image_path = sys.argv[1]
    original_path, processed_path = detect_and_process_face(image_path)

    if original_path and processed_path:
        # Generate embeddings for both original and processed faces
        original_embedding = generate_embedding(original_path)
        processed_embedding = generate_embedding(processed_path)

        print(f"Original embedding: {original_embedding}", flush=True)
        print(f"Processed embedding: {processed_embedding}", flush=True)
        print(f"Original path: {original_path}", flush=True)
        print(f"Processed path: {processed_path}", flush=True)
    else:
        print("Face not detected or error occurred.", flush=True)
        sys.exit(1)
