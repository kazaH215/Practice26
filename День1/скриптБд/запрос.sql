SELECT 
    u.username,
    r.role_name,
    res.resource_name,
    a.access_type
FROM Users u
JOIN Roles r ON u.role_id = r.role_id
JOIN Access a ON u.user_id = a.user_id
JOIN Resources res ON a.resource_id = res.resource_id;