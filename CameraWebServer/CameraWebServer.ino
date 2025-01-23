#include "esp_camera.h"
#include <WiFi.h>
#include <PubSubClient.h>

// ===================
// Chọn camera model
// ===================
#define CAMERA_MODEL_AI_THINKER  // ESP32-CAM AI Thinker
#include "camera_pins.h"
#define LED_1 14
#define LED_2 15
#define LOCK 13
#define LED_PIN 4

// ===========================
// Nhập thông tin WiFi
// ===========================
const char *ssid = "Vux";                // Thay bằng tên WiFi của bạn
const char *password = "abc123456";         // Thay bằng mật khẩu WiFi
const char *mqtt_server = "192.168.182.138";    // IP của MQTT Broker

// ==========================
// Khởi tạo các đối tượng
// ==========================
WiFiClient espClient;
PubSubClient client(espClient);

String mqttMessage = "";                     // Biến lưu thông điệp nhận từ MQTT
unsigned long lastMQTTMessageTime = 0;       // Lưu thời gian nhận MQTT cuối cùng
const unsigned long MQTT_TIMEOUT = 5000;     // Thời gian chờ 5 giây

// Hàm callback khi nhận dữ liệu từ MQTT
void mqttCallback(char *topic, byte *payload, unsigned int length) {
  Serial.print("Nhận dữ liệu từ topic: ");
  Serial.println(topic);

  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';  // Thêm ký tự null vào cuối chuỗi

  Serial.print("Dữ liệu nhận: ");
  Serial.println(message);

  mqttMessage = String(message);             // Lưu thông điệp vào biến mqttMessage
  lastMQTTMessageTime = millis();            // Cập nhật thời gian nhận tín hiệu MQTT

  if (mqttMessage == "capture") {
    Serial.println("Chụp ảnh...");
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Không thể chụp ảnh");
      return;
    }
    esp_camera_fb_return(fb);
    Serial.println("Ảnh đã được chụp");
  }
}

// Kết nối MQTT
void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Đang kết nối MQTT...");
    if (client.connect("ESP32Client")) {  // ID của ESP32
      Serial.println("Đã kết nối MQTT");
      client.subscribe("esp32/data");    // Đăng ký chủ đề cần nhận
    } else {
      Serial.print("Kết nối thất bại, rc=");
      Serial.print(client.state());
      Serial.println(" Thử lại sau 5 giây...");
      delay(5000);
    }
  }
}

// Khởi tạo camera server
void startCameraServer();

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

  // Cấu hình camera
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  if (psramFound()) {
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.fb_location = CAMERA_FB_IN_DRAM;
  }

  // Khởi tạo camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Lỗi khởi tạo camera: 0x%x\n", err);
    ESP.restart();
  }

  // Kết nối WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi đã kết nối");
  Serial.println("Địa chỉ IP: ");
  Serial.println(WiFi.localIP());

  // Khởi chạy server camera
  startCameraServer();

  // Kết nối MQTT
  client.setServer(mqtt_server, 1883);
  client.setCallback(mqttCallback);

  Serial.println("Hệ thống sẵn sàng");
  pinMode(LED_1, OUTPUT);
  pinMode(LED_2, OUTPUT);
  pinMode(LOCK, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  // digitalWrite(LED_PIN, HIGH);
  if (!client.connected()) {
    reconnectMQTT();
  }
  client.loop();

  unsigned long currentTime = millis();

  if ((currentTime - lastMQTTMessageTime) <= MQTT_TIMEOUT)
  {
    digitalWrite(LED_1, LOW);
    digitalWrite(LED_2, LOW);
    digitalWrite(LOCK, HIGH);
    if(mqttMessage == "unknown")
    {
      digitalWrite(LED_1, HIGH);
      digitalWrite(LED_2, LOW);
      digitalWrite(LOCK, HIGH);
    }
    else
    {
      digitalWrite(LED_1, LOW);
      digitalWrite(LED_2, HIGH);
      digitalWrite(LOCK, LOW);
    }
  }
  else
  {
    digitalWrite(LED_1, HIGH);
    digitalWrite(LED_2, LOW);
    digitalWrite(LOCK, HIGH);
  }

  delay(1000); // Chờ 1 giây trước khi tiếp tục vòng lặp
}
