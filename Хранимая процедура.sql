-- ==========================================
-- Хранимая процедура FilteringRequests (без представления)
-- ==========================================

CREATE OR REPLACE FUNCTION FilteringRequests(
    p_request_type VARCHAR DEFAULT NULL,
    p_department_id INT DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    id INT,
    request_type VARCHAR,
    user_id INT,
    user_email VARCHAR,
    user_name VARCHAR,
    last_name VARCHAR,
    first_name VARCHAR,
    patronymic VARCHAR,
    start_date DATE,
    end_date DATE,
    visit_purpose TEXT,
    department_name VARCHAR,
    employee_name VARCHAR,
    status VARCHAR,
    rejection_reason TEXT,
    created_at TIMESTAMP,
    group_name VARCHAR,
    visitor_count INT
) AS $$
BEGIN
    -- Индивидуальные заявки
    RETURN QUERY
    SELECT 
        vr.request_id::INT,
        'Индивидуальная'::VARCHAR,
        vr.user_id::INT,
        u.email::VARCHAR,
        u.full_name::VARCHAR,
        vr.last_name::VARCHAR,
        vr.first_name::VARCHAR,
        vr.patronymic::VARCHAR,
        vr.start_date::DATE,
        vr.end_date::DATE,
        vr.visit_purpose::TEXT,
        d.department_name::VARCHAR,
        e.full_name::VARCHAR,
        vr.status::VARCHAR,
        vr.rejection_reason::TEXT,
        vr.created_at::TIMESTAMP,
        NULL::VARCHAR,
        NULL::INT
    FROM VisitRequests vr
    LEFT JOIN Users u ON vr.user_id = u.user_id
    LEFT JOIN Departments d ON vr.department_id = d.department_id
    LEFT JOIN Employees e ON vr.employee_id = e.employee_id
    WHERE (p_request_type IS NULL OR 'Индивидуальная' = p_request_type)
      AND (p_department_id IS NULL OR d.department_id = p_department_id)
      AND (p_status IS NULL OR vr.status = p_status)
    
    UNION ALL
    
    -- Групповые заявки
    SELECT 
        gr.group_request_id::INT,
        'Групповая'::VARCHAR,
        gr.user_id::INT,
        u.email::VARCHAR,
        u.full_name::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        gr.start_date::DATE,
        gr.end_date::DATE,
        gr.visit_purpose::TEXT,
        d.department_name::VARCHAR,
        e.full_name::VARCHAR,
        gr.status::VARCHAR,
        gr.rejection_reason::TEXT,
        gr.created_at::TIMESTAMP,
        gr.group_name::VARCHAR,
        gr.visitor_count::INT
    FROM GroupVisitRequests gr
    LEFT JOIN Users u ON gr.user_id = u.user_id
    LEFT JOIN Departments d ON gr.department_id = d.department_id
    LEFT JOIN Employees e ON gr.employee_id = e.employee_id
    WHERE (p_request_type IS NULL OR 'Групповая' = p_request_type)
      AND (p_department_id IS NULL OR d.department_id = p_department_id)
      AND (p_status IS NULL OR gr.status = p_status)
    
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;