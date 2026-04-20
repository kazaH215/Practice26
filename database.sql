-- ==========================================
-- БАЗА ДАННЫХ «ХранительПРО»
-- Скрипт создания и заполнения
-- ==========================================

-- 1. УДАЛЕНИЕ СТАРЫХ ТАБЛИЦ (если есть)
DROP TABLE IF EXISTS GroupVisitors CASCADE;
DROP TABLE IF EXISTS GroupVisitRequests CASCADE;
DROP TABLE IF EXISTS VisitRequests CASCADE;
DROP TABLE IF EXISTS AccessLog CASCADE;
DROP TABLE IF EXISTS Access CASCADE;
DROP TABLE IF EXISTS Resources CASCADE;
DROP TABLE IF EXISTS Sessions CASCADE;
DROP TABLE IF EXISTS Incidents CASCADE;
DROP TABLE IF EXISTS BlackList CASCADE;
DROP TABLE IF EXISTS Employees CASCADE;
DROP TABLE IF EXISTS Departments CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Roles CASCADE;

-- 2. СОЗДАНИЕ ТАБЛИЦ

-- Роли пользователей
CREATE TABLE Roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

-- Пользователи
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    role_id INT DEFAULT 2 REFERENCES Roles(role_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Подразделения
CREATE TABLE Departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

-- Сотрудники
CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department_id INT REFERENCES Departments(department_id),
    division VARCHAR(100),
    code VARCHAR(20) UNIQUE,
    position VARCHAR(100)
);

-- Индивидуальные заявки
CREATE TABLE VisitRequests (
    request_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    visit_purpose TEXT NOT NULL,
    department_id INT REFERENCES Departments(department_id),
    employee_id INT REFERENCES Employees(employee_id),
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100) NOT NULL,
    organization VARCHAR(100),
    note TEXT NOT NULL,
    birth_date DATE NOT NULL,
    passport_series VARCHAR(4) NOT NULL,
    passport_number VARCHAR(6) NOT NULL,
    status VARCHAR(20) DEFAULT 'проверка',
    rejection_reason TEXT,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Групповые заявки
CREATE TABLE GroupVisitRequests (
    group_request_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    visit_purpose TEXT NOT NULL,
    department_id INT REFERENCES Departments(department_id),
    employee_id INT REFERENCES Employees(employee_id),
    group_name VARCHAR(100),
    visitor_count INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'проверка',
    rejection_reason TEXT,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Посетители в группе
CREATE TABLE GroupVisitors (
    visitor_id SERIAL PRIMARY KEY,
    group_request_id INT REFERENCES GroupVisitRequests(group_request_id) ON DELETE CASCADE,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    birth_date DATE NOT NULL,
    passport_series VARCHAR(4) NOT NULL,
    passport_number VARCHAR(6) NOT NULL
);

-- Чёрный список
CREATE TABLE BlackList (
    blacklist_id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    passport_series VARCHAR(4) NOT NULL,
    passport_number VARCHAR(6) NOT NULL,
    reason TEXT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    added_by INT REFERENCES Employees(employee_id)
);

-- 3. ПРЕДСТАВЛЕНИЕ (объединяет заявки)
CREATE OR REPLACE VIEW ViewListRequests AS
SELECT 
    request_id as id,
    'Индивидуальная' as request_type,
    last_name, first_name, start_date, end_date,
    visit_purpose, department_name, status, created_at
FROM VisitRequests vr
LEFT JOIN Departments d ON vr.department_id = d.department_id
UNION ALL
SELECT 
    group_request_id as id,
    'Групповая' as request_type,
    group_name as last_name, '' as first_name,
    start_date, end_date, visit_purpose,
    department_name, status, created_at
FROM GroupVisitRequests gr
LEFT JOIN Departments d ON gr.department_id = d.department_id;

-- 4. ХРАНИМАЯ ПРОЦЕДУРА (фильтрация)
CREATE OR REPLACE FUNCTION FilteringRequests(
    p_request_type VARCHAR DEFAULT NULL,
    p_department_id INT DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL
)
RETURNS SETOF ViewListRequests AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM ViewListRequests v
    WHERE (p_request_type IS NULL OR v.request_type = p_request_type)
      AND (p_department_id IS NULL OR v.department_name IN (
          SELECT department_name FROM Departments WHERE department_id = p_department_id
      ))
      AND (p_status IS NULL OR v.status = p_status);
END;
$$ LANGUAGE plpgsql;

-- 5. ТРИГГЕР (генерация логина)
CREATE OR REPLACE FUNCTION generate_visitor_login()
RETURNS TRIGGER AS $$
DECLARE login_part VARCHAR; ind INTEGER;
BEGIN
    ind := POSITION('@' IN NEW.email);
    IF ind > 0 THEN login_part := LEFT(NEW.email, ind - 1);
    ELSE login_part := NEW.email; END IF;
    NEW.login := CONCAT(login_part, NEW.id);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 6. ЗАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ
INSERT INTO Roles (role_name) VALUES ('Admin'), ('User'), ('Guest');
INSERT INTO Departments (department_name) VALUES 
('Производство'), ('Сбыт'), ('Администрация'), ('Служба безопасности'), ('Планирование'), ('Общий отдел'), ('Охрана');
INSERT INTO Employees (full_name, department_id, division, code) VALUES
('Фомичева Авдотья Трофимовна', 1, NULL, '9367788'),
('Гаврилова Римма Ефимовна', 2, NULL, '9788737'),
('Савельев Павел Степанович', 6, 'Общий отдел', '9768239'),
('Чернов Всеволод Наумович', 7, 'Охрана', '9404040');
INSERT INTO Users (email, password_hash, full_name, role_id) VALUES
('admin@hranitel.ru', MD5('Admin123!'), 'Администратор', 1),
('user@hranitel.ru', MD5('User123!'), 'Пользователь', 2);