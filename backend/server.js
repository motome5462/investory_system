const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// 1. เชื่อมต่อ MySQL (ปรับแต่ง User/Password ตามเครื่องคุณ)
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '1234', 
    database: 'inventory_system'
});

db.connect(err => {
    if (err) console.error('Database connection failed: ' + err.stack);
    console.log('Connected to MySQL Database.');
});

// 2. API Login (แบบจำลอง)
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    // ในแอปจริงควรเช็คจากตาราง users
    if (username === 'admin' && password === '1234') {
        res.json({ status: 'success', user_id: 1 });
    } else {
        res.status(401).json({ status: 'error', message: 'Login Failed' });
    }
});

// 3. API บันทึกหน้าแรก (Projects)
app.post('/api/projects', (req, res) => {
    const { project_name, project_date, project_time, project_detail } = req.body;
    const sql = "INSERT INTO projects (project_name, project_date, project_time, project_detail) VALUES (?, ?, ?, ?)";
    db.query(sql, [project_name, project_date, project_time, project_detail], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ project_id: result.insertId }); // ส่ง ID กลับไปให้ Flutter
    });
});

// 4. API บันทึกหน้าที่สอง (Items)
app.post('/api/items', (req, res) => {
    const { project_id, item_name, quantity, sn_number, note } = req.body;
    const sql = "INSERT INTO withdrawal_items (project_id, item_name, quantity, sn_number, note) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [project_id, item_name, quantity, sn_number, note], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ status: 'success' });
    });
});

// API สำหรับดึงโครงการทั้งหมดมาแสดงที่หน้า Home
app.get('/api/projects', (req, res) => {
    const sql = "SELECT * FROM projects ORDER BY created_at DESC";
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

// 1. ดึงข้อมูลโครงการและรายการสินค้า
app.get('/api/projects/:id', (req, res) => {
    const projectId = req.params.id;
    const sqlProject = "SELECT * FROM projects WHERE id = ?";
    const sqlItems = "SELECT * FROM items WHERE project_id = ?";

    db.query(sqlProject, [projectId], (err, projectResult) => {
        if (err) return res.status(500).send(err);
        db.query(sqlItems, [projectId], (err, itemsResult) => {
            if (err) return res.status(500).send(err);
            res.json({ project: projectResult[0], items: itemsResult });
        });
    });
});

// 2. อัปเดตข้อมูลโครงการ (ใช้ PUT)
app.put('/api/projects/:id', (req, res) => {
    const { project_name, project_date, project_detail } = req.body;
    const sql = "UPDATE projects SET project_name = ?, project_date = ?, project_detail = ? WHERE id = ?";
    db.query(sql, [project_name, project_date, project_detail, req.params.id], (err, result) => {
        if (err) return res.status(500).send(err);
        res.json({ message: "Updated successfully" });
    });
});

app.listen(3000, () => console.log('Backend Server running on port 3000'));