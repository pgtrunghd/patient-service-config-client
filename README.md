# Bài 2 – Kết nối Patient Service với Config Server

Đề bài: https://portal.rikkei.edu.vn/learn/159/homework/8902

Patient Service lấy cấu hình PostgreSQL từ Config Server khi khởi động bằng
`spring-cloud-starter-config` và `spring.config.import`. Toàn bộ cấu hình datasource
và JPA nằm trong `patient-service.properties` của kho Git cục bộ `medical-config-repo`.

Mã nguồn Patient Service được phát triển tiếp từ bài trước:
https://github.com/pgtrunghd/module4-session6-exercise2

## Yêu cầu

- JDK 21, Git, PostgreSQL chạy tại `localhost:5432`.
- Spring Boot 3.5.6, Spring Cloud 2025.0.0, Gradle Wrapper 8.14.3.
- Config Server bài 1: https://github.com/pgtrunghd/config-server

## 1. Chuẩn bị cấu hình trên Git

Đặt hai project cạnh nhau. Từ thư mục project này, chạy:

```bash
./scripts/prepare-config-repo.sh
```

Script tạo `../medical-config-repo` nếu chưa có, chép cấu hình mẫu và commit trên
nhánh `main`. Nếu kho đã tồn tại, script yêu cầu kho sạch trước khi cập nhật file
`patient-service.properties`; có thể chạy lại mà không tạo commit dư thừa.
Có thể truyền một đường dẫn kho khác làm tham số thứ nhất.

Cấu hình được chuyển lên Git:

```properties
server.port=8081
message=Chao mung den voi Patient Service tu Config Server
spring.datasource.url=jdbc:postgresql://localhost:${PATIENT_DB_PORT:5432}/patient_db
spring.datasource.username=postgres
spring.datasource.password=123456
spring.jpa.hibernate.ddl-auto=update
```

Cổng mặc định là `5432`. Có thể đặt biến môi trường `PATIENT_DB_PORT` khi chạy
Patient Service để dùng cổng khác; URL database vẫn được nạp từ Git qua Config Server.

Các thông tin `postgres` / `123456` là tài khoản mẫu theo đề, dành cho cơ sở dữ liệu
thực hành cục bộ. Điều chỉnh file trong kho Git theo PostgreSQL của bạn rồi commit.
File có tên chính xác `patient-service.properties`, không có đuôi `.txt`.

## 2. Chuẩn bị PostgreSQL

Tạo database `patient_db` với tài khoản mẫu của đề. Ví dụ khi đã có role `postgres`:

```bash
psql -h localhost -U postgres -d postgres -c 'CREATE DATABASE patient_db;'
```

Nếu database đã tồn tại thì bỏ qua lệnh tạo. Hibernate tạo/cập nhật bảng `patients`
với `spring.jpa.hibernate.ddl-auto=update` lấy từ Config Server.

## 3. Chạy Config Server trước

Trong thư mục `config-server` của bài 1:

```bash
./gradlew bootRun
```

Kiểm tra `http://localhost:8888/patient-service/default` trả các thuộc tính
`spring.datasource.*`, `spring.jpa.hibernate.ddl-auto`, `server.port=8081` cùng mã commit.
Nếu Config Server dùng đường dẫn kho khác, đặt `CONFIG_REPO_URI=file:///duong/dan/kho`.

## 4. Chạy Patient Service

Từ thư mục project này:

```bash
./gradlew bootRun
```

File `src/main/resources/application.properties` chỉ chứa đúng:

```properties
spring.application.name=patient-service
spring.config.import=optional:configserver:http://localhost:8888
```

Không khai báo URL, tài khoản, mật khẩu database hay JPA trong file cục bộ.
Config Server trả `server.port=8081`, vì vậy Patient Service chạy tại cổng 8081.

Log mong đợi có `Fetching config from server`, `Located environment`,
`HikariPool-1 - Start completed` và `Started PatientServiceApplication`.
Bài này tập trung vào Config Client nên không yêu cầu chạy Eureka.

`optional:` theo mẫu của đề cho phép bước tải cấu hình tiếp tục khi Config Server
không khả dụng. Tuy nhiên, ứng dụng này vẫn cần cấu hình PostgreSQL từ xa để khởi
động JPA; vì vậy hãy chạy PostgreSQL và Config Server trước.

## 5. Kiểm thử

```bash
./gradlew clean test bootJar
./scripts/verify.sh
```

Ba test controller kiểm tra tạo bệnh nhân, dữ liệu thiếu tên và trường hợp không tìm thấy.
Các test này tắt Config Client để kiểm tra riêng controller.

Script kiểm thử toàn luồng yêu cầu các dịch vụ đang chạy: xác minh cấu hình PostgreSQL
và mã commit từ Config Server, tạo một bản ghi bệnh nhân mẫu qua HTTP 201, rồi đọc
lại qua HTTP 200. Script tạo một bản ghi `Config Client Smoke Test` mỗi lần chạy.

API giữ nguyên từ bài trước:

- `POST /api/v1/patients` với JSON `{"fullName":"Nguyen Van A","address":"Ha Noi"}`.
- `GET /api/v1/patients/{id}` để đọc bệnh nhân từ PostgreSQL.

## Nộp bài

Repository này chứa Patient Service, cấu hình Git mẫu và script tái tạo kho cấu hình.
Dán link repository này vào bài tập 8902 trên Rikkei.

Tham khảo: [Spring Cloud Config Client](https://docs.spring.io/spring-cloud-config/reference/4.3/client.html).
