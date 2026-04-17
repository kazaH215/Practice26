-- ==========================================
-- ЗАДАНИЕ 3: Представление ViewListRequests (ИСПРАВЛЕННОЕ)
-- ==========================================

CREATE OR REPLACE VIEW ViewListRequests AS
SELECT 
    request_id as id,
    'Индивидуальная' as request_type,
    vr.user_id,
    u.email as user_email,
    u.full_name as user_name,
    vr.last_name,
    vr.first_name,
    vr.patronymic,
    vr.start_date,
    vr.end_date,
    vr.visit_purpose,
    d.department_name,
    e.full_name as employee_name,
    vr.status,
    vr.rejection_reason,
    vr.created_at,
    NULL::varchar as group_name,
    NULL::int as visitor_count
FROM VisitRequests vr
LEFT JOIN Users u ON vr.user_id = u.user_id
LEFT JOIN Departments d ON vr.department_id = d.department_id
LEFT JOIN Employees e ON vr.employee_id = e.employee_id

UNION ALL

SELECT 
    group_request_id as id,
    'Групповая' as request_type,
    gr.user_id,
    u.email as user_email,
    u.full_name as user_name,
    NULL::varchar as last_name,
    NULL::varchar as first_name,
    NULL::varchar as patronymic,
    gr.start_date,
    gr.end_date,
    gr.visit_purpose,
    d.department_name,
    e.full_name as employee_name,
    gr.status,
    gr.rejection_reason,
    gr.created_at,
    gr.group_name,
    gr.visitor_count
FROM GroupVisitRequests gr
LEFT JOIN Users u ON gr.user_id = u.user_id
LEFT JOIN Departments d ON gr.department_id = d.department_id
LEFT JOIN Employees e ON gr.employee_id = e.employee_id;

-- Проверка представления
SELECT * FROM ViewListRequests ORDER BY created_at DESC;