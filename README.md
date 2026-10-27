# Patient Service – Config Client và Profiles (Bài 2, 3)

Đề bài 2: https://portal.rikkei.edu.vn/learn/159/homework/8902

Đề bài 3: https://portal.rikkei.edu.vn/learn/159/homework/8903

Patient Service lấy cấu hình PostgreSQL từ Config Server khi khởi động bằng
`spring-cloud-starter-config` và `spring.config.import`. Toàn bộ cấu hình datasource
và JPA nằm trong các file `patient-service*.properties` của kho Git cục bộ `medical-config-repo`.

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

Script tạo `../medical-config-repo` nếu chưa có, chép ba file cấu hình mẫu và commit trên
nhánh `main`. Nếu kho đã tồn tại, script yêu cầu kho sạch trước khi cập nhật ba file
`patient-service*.properties`; có thể chạy lại mà không tạo commit dư thừa.
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

## Bài 3 – Chuyển đổi môi trường bằng Profiles

Sử dụng lại Config Server và Patient Service của hai bài trước. Client vẫn chỉ
có hai dòng trong `application.properties`; không cần sửa mã Java khi chuyển database.
Runtime đã có đủ JDBC driver PostgreSQL và MySQL Connector/J.

| Profile | File trong Git | Cổng ứng dụng | Database mặc định |
| --- | --- | --- | --- |
| `dev` | `patient-service-dev.properties` | 8081 | MySQL, localhost:3306/patient_db |
| `prod` | `patient-service-prod.properties` | 8082 | PostgreSQL, localhost:5432/patient_db |

`patient-service.properties` giữ cấu hình mặc định của bài 2. Khi chọn profile,
file tương ứng có độ ưu tiên cao hơn và ghi đè URL, driver, tài khoản, cổng ứng dụng.
Các profile sử dụng `ddl-auto=update` theo bài thực hành.

Cập nhật kho cấu hình và tạo commit:

```bash
./scripts/prepare-config-repo.sh
```

Kiểm tra Config Server đã trả đúng file profile (nằm đầu `propertySources`):

```bash
curl -f http://localhost:8888/patient-service/dev
curl -f http://localhost:8888/patient-service/prod
```

Chuẩn bị MySQL: đăng nhập bằng tài khoản quản trị MySQL trên máy, sau đó chạy SQL
cho môi trường thực hành:

```sql
CREATE DATABASE IF NOT EXISTS patient_db;
CREATE USER IF NOT EXISTS 'patient_dev'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON patient_db.* TO 'patient_dev'@'localhost';
```

PostgreSQL dùng `patient_db` và tài khoản `postgres` như phần bài 2 phía trên.
Các mật khẩu mẫu dành cho môi trường thực hành. Nếu tài khoản đã có mật khẩu khác,
chỉnh cấu hình trong kho Git cho khớp rồi commit trước khi chạy.

Chạy từng profile từ cùng một JAR:

```bash
./gradlew clean test bootJar
java -jar build/libs/patient-service-config-client-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
# Dừng ứng dụng rồi chạy profile còn lại:
java -jar build/libs/patient-service-config-client-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

Hoặc dùng Gradle:

```bash
./gradlew bootRun --args='--spring.profiles.active=dev'
./gradlew bootRun --args='--spring.profiles.active=prod'
```

Trong IntelliJ: Run → Edit Configurations → Active profiles → nhập `dev` hoặc `prod`.
Log phải có active profile tương ứng, Hikari kết nối database và Tomcat chạy tại
8081 (dev) hoặc 8082 (prod).

Khi hai profile chạy đồng thời ở hai terminal, có thể kiểm thử cả hai bằng:

```bash
./scripts/verify-profiles.sh
```

Script xác minh thứ tự ưu tiên cấu hình, cổng và JDBC driver trên Config Server,
rồi tạo/đọc bệnh nhân qua từng ứng dụng để kiểm tra kết nối database thực tế.
Mỗi lần chạy sẽ tạo một bản ghi mẫu trong mỗi database.

Nếu cổng database mặc định đang bận, dùng `PATIENT_MYSQL_PORT` cho MySQL và
`PATIENT_DB_PORT` cho PostgreSQL khi khởi động Patient Service. Cổng ứng dụng vẫn
là 8081/8082; URL database được cung cấp từ Git và phân giải biến môi trường tại client.

## Kết quả kiểm thử bài 3

Đã chạy cùng một JAR với `--spring.profiles.active=dev` và `prod`:

| Profile | Cổng ứng dụng thực tế | Database kiểm thử | Tạo/đọc qua API |
| --- | --- | --- | --- |
| dev | 8081 | MySQL 8.4, cổng 33306 | HTTP 201 / 200 |
| prod | 8082 | PostgreSQL 18, cổng 55432 | HTTP 201 / 200 |

Cổng database kiểm thử riêng được chọn bằng `PATIENT_MYSQL_PORT=33306` và
`PATIENT_DB_PORT=55432` để tránh ảnh hưởng dịch vụ có sẵn. Giá trị mặc định của
bài nộp vẫn là MySQL 3306 và PostgreSQL 5432. Config Server trả đúng file profile
ưu tiên trước file mặc định, và hai ứng dụng kết nối thành công với Hikari.
Build `clean test bootJar` đạt, ba test controller đạt.

## Nộp bài

Repository này chứa Patient Service, cấu hình Git mẫu và script tái tạo kho cấu hình.
Dán link repository này vào bài tập 8902 hoặc 8903 tương ứng trên Rikkei.

Tham khảo: [Spring Cloud Config Client](https://docs.spring.io/spring-cloud-config/reference/4.3/client.html).

Tham khảo Profiles: [Spring Cloud Config Environment Repository](https://docs.spring.io/spring-cloud-config/reference/server/environment-repository.html).
