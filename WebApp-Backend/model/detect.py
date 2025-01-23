import cv2
import os
import json
import requests
from datetime import datetime
import time
import base64
from collections import Counter
from annoy import AnnoyIndex
import face_recognition
import threading
from flask import Flask, Response
import paho.mqtt.client as mqtt

app = Flask(__name__)

# Configuration
url_embedding = "http://192.168.182.138:8081/getAllDataWithUsername"
esp32_cam_stream_url = "http://192.168.182.58:81/stream"
captured_folder = "captured_folder"
index_file = "hr_annoy_index.ann"
dimension = 128
threshold = 0.36
last_saved_time = 0
labels = []
usernames = []
member_ids = []  # Global list for member IDs
is_processing = False
broker = "192.168.182.138"
port = 1883
topic = "esp32/data"

client = mqtt.Client()

# Create required directories
os.makedirs(captured_folder, exist_ok=True)

# Load face cascade
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')


def fetch_embeddings_from_url(url):
    """Fetch image embeddings from the provided URL."""
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            embeddings = []
            for item in data:
                image_vector = item.get("image_vector")
                username = item.get("username")
                member_id = item.get("member_id")  # Include member_id
                if image_vector and username and member_id:
                    embeddings.append({"username": username, "embedding": image_vector[1], "member_id": member_id})
            return embeddings
        else:
            print(f"Failed to fetch embeddings. Status code: {response.status_code}")
            return []
    except Exception as e:
        print(f"Error fetching embeddings: {e}")
        return []


def build_annoy_index_from_url(dimension, index_file, url):
    """Build Annoy index using embeddings fetched from URL."""
    embeddings = fetch_embeddings_from_url(url)
    index = AnnoyIndex(dimension, 'angular')
    global labels, usernames, member_ids
    labels = []
    usernames = []
    member_ids = []  # Initialize member_ids list
    for i, item in enumerate(embeddings):
        embedding = item.get("embedding")
        username = item.get("username")
        member_id = item.get("member_id")
        if embedding and username and member_id:
            labels.append(i)
            usernames.append(username)
            member_ids.append(member_id)  # Store member_id
            index.add_item(i, embedding)
    if labels:
        index.build(50)
        index.save(index_file)
        print(f"Built and saved Annoy index to {index_file}.")
    else:
        print("No valid embeddings to build Annoy index.")
    return labels, usernames, member_ids  # Return member_ids


def search_in_annoy_index(query_embedding, index_file, usernames, member_ids, n=10, threshold=0.36):
    """Search for the closest match in the Annoy index."""
    index = AnnoyIndex(dimension, 'angular')
    index.load(index_file)
    nearest_indices, distances = index.get_nns_by_vector(query_embedding, n=n, include_distances=True)

    if not nearest_indices or len(usernames) <= max(nearest_indices):
        print("Unable to find corresponding usernames in Annoy index.")
        return {"username": None, "distance": None, "member_id": -1}

    result_usernames = [usernames[i] for i in nearest_indices]
    result_member_ids = [member_ids[i] for i in nearest_indices]
    label_counts = Counter(result_usernames)
    most_common_label, count = label_counts.most_common(1)[0]
    avg_distance = sum(distances) / n

    if avg_distance <= 0.36:
        most_common_member_id = result_member_ids[result_usernames.index(most_common_label)]
        return {"username": most_common_label, "distance": avg_distance, "member_id": most_common_member_id}
    else:
        print(f"Average distance ({avg_distance}) exceeds threshold ({threshold}). No suitable match.")
        return {"username": None, "distance": avg_distance, "member_id": -1}


def encode_image(file_path):
    """Encode image to a 128-dimension embedding."""
    try:
        image = face_recognition.load_image_file(file_path)
        encodings = face_recognition.face_encodings(image)
        if encodings:
            return encodings[0]
        else:
            print(f"No face found in the image: {file_path}")
            return None
    except Exception as e:
        print(f"Error encoding {file_path}: {e}")
        return None


def image_to_base64(image_path):
    """Convert image to base64."""
    with open(image_path, "rb") as img_file:
        return base64.b64encode(img_file.read()).decode('utf-8')


def send_post_request(image_base64, member_id, timestamp):
    """Send POST request with base64 image and member_id."""
    url = "http://192.168.182.138:8081/createhistories"  # Replace with your actual endpoint
    data = {
        "base64Image": image_base64,
        "member_id": member_id,
        "timestamp": timestamp
    }
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"Successfully sent data to the server. Response: {response.text}")
        else:
            print(f"Failed to send data. Status code: {response.status_code}")
    except Exception as e:
        print(f"Error sending POST request: {e}")


def generate_frames():
    """Generate video frames from the ESP32-CAM stream and handle face detection and processing."""
    global last_saved_time
    global is_processing

    # Mở kết nối với ESP32-CAM
    cap = cv2.VideoCapture(esp32_cam_stream_url)
    if not cap.isOpened():
        print("Unable to connect to ESP32-CAM.")
        return

    face_detected_time = 0  # Thời gian phát hiện khuôn mặt đầu tiên
    padding = 30  # Phần dư thêm xung quanh khuôn mặt

    while True:
        # Đọc từng khung hình từ luồng video
        ret, frame = cap.read()
        if not ret:
            print("Failed to read frame.")
            break

        # Xử lý khung hình
        print("Processing frame...")
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

        if len(faces) > 0:
            print(f"Number of faces detected: {len(faces)}")
            for (x, y, w, h) in faces:
                # Mở rộng vùng cắt khuôn mặt
                x_start = max(x - padding, 0)
                y_start = max(y - padding, 0)
                x_end = min(x + w + padding, frame.shape[1])
                y_end = min(y + h + padding, frame.shape[0])

                # Vẽ khung bao quanh khuôn mặt mở rộng
                cv2.rectangle(frame, (x_start, y_start), (x_end, y_end), (0, 255, 0), 2)

            # Lưu ảnh sau 5 giây phát hiện và đảm bảo khoảng cách giữa các lần lưu là 10 giây
            current_time = time.time()
            if face_detected_time == 0:
                face_detected_time = current_time

            if current_time - face_detected_time >= 3 and current_time - last_saved_time >= 8:
                print(f"Saving image after {current_time - face_detected_time}s and {current_time - last_saved_time}s.")
                face_detected_time = 0
                last_saved_time = current_time

                # Tạo đường dẫn và lưu ảnh
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                image_path = os.path.join(captured_folder, f"captured_{timestamp}.jpg")
                cv2.imwrite(image_path, frame)
                print(f"Saved image at: {image_path}")

                # Xử lý ảnh sau khi lưu
                if not is_processing:
                    is_processing = True

                    def process_image():
                        global is_processing
                        image_base64 = None  # Khởi tạo để tránh lỗi nếu không gán giá trị
                        try:
                            print("Processing image...")
                            query_embedding = encode_image(image_path)
                            if query_embedding is not None:
                                print("Encoded image successfully.")
                                result = search_in_annoy_index(query_embedding, index_file, usernames, member_ids, threshold=threshold)
                                print(f"Search result: {result}")

                                # Chuyển ảnh sang base64
                                image_base64 = image_to_base64(image_path)
                                if result["username"]:
                                    print(f"Sending post request for username {result['username']}.")
                                    member_id = result["member_id"]
                                    client.publish(topic, result["username"])
                                    send_post_request(image_base64, member_id, timestamp)
                                else:
                                    print("No suitable match found within the threshold.")
                                    client.publish(topic, "unknown")
                                    member_id = -1
                                    send_post_request(image_base64, member_id, timestamp)
                            else:
                                print("Unable to generate embedding for the image.")
                                client.publish(topic, "unknown")
                                member_id = -1
                                send_post_request(image_base64, member_id, timestamp)
                        except Exception as e:
                            print(f"Error processing image: {e}")
                            client.publish(topic, "unknown")
                            member_id = -1
                            send_post_request(image_base64, member_id, timestamp)
                        finally:
                            is_processing = False

                    threading.Thread(target=process_image).start()

        else:
            face_detected_time = 0

        # Chuyển đổi khung hình thành định dạng JPEG để hiển thị
        _, buffer = cv2.imencode('.jpg', frame)
        frame = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n\r\n')

@app.route('/video_feed')
def video_feed():
    """Video streaming route."""
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')


@app.before_first_request
def init():
    """Initialize the application by building the Annoy index."""
    print("Initializing Annoy index...")
    build_annoy_index_from_url(dimension, index_file, url_embedding)
    print("Annoy index initialized.")


if __name__ == '__main__':
    client.connect(broker, port)
    app.run(host='0.0.0.0', port=9999)
