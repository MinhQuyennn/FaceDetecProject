import face_recognition
from PIL import Image
import sys 
import os

def detect_and_crop_face(image_path):
    print(f"Processing image: {image_path}")  # Log the image path

    # Load the image using face_recognition
    image = face_recognition.load_image_file(image_path)

    # Detect face locations
    face_locations = face_recognition.face_locations(image)

    if not face_locations:
        print("No face detected!")
        return None

    # Process the first detected face
    top, right, bottom, left = face_locations[0]
    cropped_image = image[top:bottom, left:right]

    # Create the output path for the cropped image (same directory as input)
    output_path = os.path.join(os.path.dirname(image_path), 'cropped_face.jpg')

    # Save the cropped image using PIL
    cropped_img_pil = Image.fromarray(cropped_image)
    cropped_img_pil.save(output_path, 'JPEG')  # Explicitly save as JPEG
    print(f"Face detected and image cropped successfully! Saved to: {output_path}")
    return output_path  # Return the path of the cropped image

# Main logic
if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python face_crop.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    result = detect_and_crop_face(image_path)
    if result is None:
        print("No face detected or error occurred.")
        sys.exit(1)
    else:
        print(f"Successfully cropped the face: {result}")
