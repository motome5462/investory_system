const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json());

// สร้างโฟลเดอร์ uploads หากยังไม่มี
const uploadDir = './uploads';
if (!fs.existsSync(uploadDir)){
    fs.mkdirSync(uploadDir);
}

// เปิดให้เข้าถึงรูปภาพผ่าน URL
app.use('/uploads', express.static('uploads'));

// เชื่อมต่อ MySQL
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

// ตั้งค่า Multer
const storage = multer.diskStorage({
    destination: './uploads/',
    filename: function(req, file, cb) {
        cb(null, 'item-' + Date.now() + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// --- API Login, Projects (คงเดิมทั้งหมด) ---
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    const sql = "SELECT id, full_name FROM users WHERE username = ? AND password = ?";
    db.query(sql, [username, password], (err, results) => {
        if (err) return res.status(500).json(err);
        if (results.length > 0) res.json({ status: 'success', user_id: results[0].id, full_name: results[0].full_name });
        else res.status(401).json({ status: 'error', message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' });
    });
});

app.post('/api/projects', (req, res) => {
    const { project_name, project_date, project_time, project_detail, user_id } = req.body;
    const sql = "INSERT INTO projects (project_name, project_date, project_time, project_detail, user_id) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [project_name, project_date, project_time, project_detail, user_id || 1], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ project_id: result.insertId });
    });
});

app.get('/api/projects', (req, res) => {
    const sql = "SELECT p.*, u.full_name FROM projects p LEFT JOIN users u ON p.user_id = u.id ORDER BY p.created_at DESC";
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

app.get('/api/projects/:id', (req, res) => {
    const projectId = req.params.id;
    db.query("SELECT * FROM projects WHERE id = ?", [projectId], (err, projectResults) => {
        if (err) return res.status(500).json({ error: err.message });
        if (projectResults.length === 0) return res.status(404).json({ message: "ไม่พบโครงการ" });
        db.query("SELECT * FROM withdrawal_items WHERE project_id = ?", [projectId], (err, itemResults) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ project: projectResults[0], items: itemResults });
        });
    });
});

app.put('/api/projects/:id', (req, res) => {
    const projectId = req.params.id;
    const { project_name, project_date, project_detail } = req.body;
    const sql = "UPDATE projects SET project_name = ?, project_date = ?, project_detail = ? WHERE id = ?";
    db.query(sql, [project_name, project_date, project_detail, projectId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "Success" });
    });
});

// --- API Items (แก้ไขจุดติดขัด) ---

// API บันทึกสินค้าตัวเดียวที่รองรับรูปภาพ (ลบตัวซ้ำออกแล้ว)
app.post('/api/items', upload.single('image'), (req, res) => {
    try {
        const { project_id, item_name, sn_numbers, note } = req.body;
        if (!project_id || !sn_numbers) return res.status(400).json({ message: "ข้อมูลไม่ครบถ้วน" });

        const image_url = req.file ? `/uploads/${req.file.filename}` : null;
        const sns = JSON.parse(sn_numbers); // แปลง JSON string เป็น Array

        const sql = "INSERT INTO withdrawal_items (project_id, item_name, quantity, sn_number, note, image_url) VALUES ?";
        const values = sns.map(sn => [project_id, item_name, 1, sn, note || null, image_url]);

        db.query(sql, [values], (err, result) => {
            if (err) return res.status(500).json(err);
            res.status(201).json({ status: 'success' });
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

app.delete('/api/items/:id', (req, res) => {
    const sql = "DELETE FROM withdrawal_items WHERE id = ?";
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ status: 'success' });
    });
});

app.listen(3000, () => console.log('Server running on port 3000'));