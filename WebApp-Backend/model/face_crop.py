import face_recognition
import cv2
import os
import json
from PIL import Image
import sys

def detect_and_process_face(image_path):
    print(f"Processing image: {image_path}", flush=True)
    try:
        # Load the image
        image = face_recognition.load_image_file(image_path)

        # Detect face locations
        face_locations = face_recognition.face_locations(image)

        if not face_locations:
            print("No face detected! Skipping...", flush=True)
            return None, None

        # Select the first detected face and expand with padding
        top, right, bottom, left = face_locations[0]

        # Define padding
        padding = 30

        # Get image dimensions
        image_height, image_width, _ = image.shape

        # Expand the crop
        top = max(0, top - padding)
        right = min(image_width, right + padding)
        bottom = min(image_height, bottom + padding)
        left = max(0, left - padding)

        # Crop the expanded region
        face_np = image[top:bottom, left:right]

        # Save the expanded cropped face
        expanded_output_path = os.path.join(
            os.path.dirname(image_path), 'expanded_cropped_face.jpg'
        )
        Image.fromarray(face_np).save(expanded_output_path, 'JPEG')

        print(f"Expanded cropped face saved to: {expanded_output_path}", flush=True)


        # Process face
        # Apply median blur
        face_np = cv2.medianBlur(face_np, 1)

        # Convert to YUV and equalize histogram for brightness
        face_yuv = cv2.cvtColor(face_np, cv2.COLOR_RGB2YUV)
        face_yuv[:, :, 0] = cv2.equalizeHist(face_yuv[:, :, 0])
        processed_face = cv2.cvtColor(face_yuv, cv2.COLOR_YUV2RGB)

        # Apply bilateral filter for smoothness
        processed_face = cv2.bilateralFilter(processed_face, d=9, sigmaColor=75, sigmaSpace=75)

        # Save the processed face
        processed_output_path = os.path.join(
            os.path.dirname(image_path), 'processed_face.jpg'
        )
        Image.fromarray(processed_face).save(processed_output_path, 'JPEG')

        print(f"Original face saved to: {expanded_output_path}", flush=True)
        print(f"Processed face saved to: {processed_output_path}", flush=True)

        return expanded_output_path, processed_output_path

    except Exception as e:
        print(f"Error processing image: {e}", flush=True)
        return None, None


def generate_embedding(image_path):
    try:
        # Load the image
        image = face_recognition.load_image_file(image_path)

        # Detect face locations
        face_locations = face_recognition.face_locations(image)

        if not face_locations:
            print("No face detected! Skipping embedding generation.", flush=True)
            return None

        # Generate embedding for the first face
        encodings = face_recognition.face_encodings(image, known_face_locations=[face_locations[0]])
        if encodings:
            return encodings[0].tolist()
        else:
            print("No encoding found for the face.", flush=True)
            return None
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