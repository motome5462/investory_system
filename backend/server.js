const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const multer = require('multer');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// 1. เชื่อมต่อ MySQL
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

// 2. API Login (เช็คจากตาราง users ตามจริง)
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    const sql = "SELECT id, full_name FROM users WHERE username = ? AND password = ?";
    db.query(sql, [username, password], (err, results) => {
        if (err) return res.status(500).json(err);
        if (results.length > 0) {
            res.json({ status: 'success', user_id: results[0].id, full_name: results[0].full_name });
        } else {
            res.status(401).json({ status: 'error', message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' });
        }
    });
});

// 3. API บันทึกโครงการใหม่
app.post('/api/projects', (req, res) => {
    const { project_name, project_date, project_time, project_detail, user_id } = req.body;
    const sql = "INSERT INTO projects (project_name, project_date, project_time, project_detail, user_id) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [project_name, project_date, project_time, project_detail, user_id || 1], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ project_id: result.insertId });
    });
});

// 4. API สำหรับดึงโครงการทั้งหมด (Join กับตาราง users เพื่อเอาชื่อผู้บันทึก)
app.get('/api/projects', (req, res) => {
    const sql = `
        SELECT p.*, u.full_name 
        FROM projects p 
        LEFT JOIN users u ON p.user_id = u.id 
        ORDER BY p.created_at DESC`;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

// 5. API ดึงข้อมูลโครงการ พร้อมรายการสินค้า (ใช้ตาราง withdrawal_items ตามภาพ)
app.get('/api/projects/:id', (req, res) => {
    const projectId = req.params.id;
    // Query แรก: ดึงข้อมูลโครงการ
    db.query("SELECT * FROM projects WHERE id = ?", [projectId], (err, projectResults) => {
        if (err) return res.status(500).json({ error: err.message });
        if (projectResults.length === 0) return res.status(404).json({ message: "ไม่พบโครงการ" });

        // Query ที่สอง: ดึงสินค้าจากตาราง withdrawal_items
        db.query("SELECT * FROM withdrawal_items WHERE project_id = ?", [projectId], (err, itemResults) => {
            if (err) return res.status(500).json({ error: err.message });

            res.json({
                project: projectResults[0],
                items: itemResults
            });
        });
    });
});

// 6. แก้ไขข้อมูลโครงการ
// แก้ไขข้อมูลโครงการ (PUT)
app.put('/api/projects/:id', (req, res) => {
    const projectId = req.params.id;
    const { project_name, project_date, project_detail } = req.body;
    
    const sql = "UPDATE projects SET project_name = ?, project_date = ?, project_detail = ? WHERE id = ?";
    
    db.query(sql, [project_name, project_date, project_detail, projectId], (err, result) => {
        if (err) {
            console.error("Update Error:", err);
            return res.status(500).json({ error: err.message });
        }
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: "ไม่พบข้อมูลโครงการที่ต้องการแก้ไข" });
        }

        res.json({ message: "Success" });
    });
});

// 7. เพิ่มสินค้าใหม่เข้าไปในโครงการ (ใช้ตาราง withdrawal_items)
app.post('/api/items', (req, res) => {
    // ต้องรับค่า note มาจาก Flutter ด้วย
    const { project_id, item_name, sn_number, quantity, note } = req.body;
    const sql = "INSERT INTO withdrawal_items (project_id, item_name, sn_number, quantity, note) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [project_id, item_name, sn_number, quantity, note || null], (err, result) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({ status: 'success', id: result.insertId });
    });
});

// API สำหรับลบรายการสินค้ารายตัว
app.delete('/api/items/:id', (req, res) => {
    const itemId = req.params.id;
    const sql = "DELETE FROM withdrawal_items WHERE id = ?";
    
    db.query(sql, [itemId], (err, result) => {
        if (err) {
            console.error("Error deleting item:", err);
            return res.status(500).json({ error: err.message });
        }
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: "ไม่พบรายการสินค้าที่ต้องการลบ" });
        }

        res.json({ status: 'success', message: 'ลบรายการสินค้าเรียบร้อยแล้ว' });
    });
});

// ตั้งค่าการเก็บไฟล์
// ตั้งค่าการเก็บไฟล์ (ย้ายไว้ด้านบน API)
const storage = multer.diskStorage({
    destination: './uploadimages/',
    filename: function(req, file, cb) {
        cb(null, 'item-' + Date.now() + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// API สำหรับเพิ่มสินค้า (รองรับทั้งรูปภาพ และข้อมูลแบบอาเรย์ SN)
app.post('/api/items', upload.single('image'), (req, res) => {
    try {
        const { project_id, item_name, quantity, sn_numbers, note } = req.body;
        
        // ตรวจสอบข้อมูลเบื้องต้น
        if (!project_id || !item_name || !sn_numbers) {
            return res.status(400).json({ message: "ข้อมูลส่งมาไม่ครบถ้วน (Check project_id, item_name, sn_numbers)" });
        }

        const image_url = req.file ? `/uploadimages/${req.file.filename}` : null;
        
        // แปลง JSON string ของ SN จาก Flutter เป็น List
        const sns = JSON.parse(sn_numbers); 

        // เตรียมข้อมูลสำหรับ Bulk Insert (INSERT ... VALUES ?)
        // หมายเหตุ: quantity ของแต่ละ SN คือ 1
        const sql = "INSERT INTO withdrawal_items (project_id, item_name, quantity, sn_number, note, image_url) VALUES ?";
        const values = sns.map(sn => [project_id, item_name, 1, sn, note || null, image_url]);

        db.query(sql, [values], (err, result) => {
            if (err) {
                console.error("Database Error:", err);
                return res.status(500).json(err);
            }
            res.json({ status: 'success', message: 'บันทึกรายการสินค้าเรียบร้อยแล้ว' });
        });
    } catch (error) {
        console.error("Server Catch Error:", error);
        res.status(500).json({ message: "Server Error: " + error.message });
    }
});

// อย่าลืมบรรทัดนี้ เพื่อให้ Flutter เข้าถึงรูปภาพได้
app.use('/uploadimages', express.static('uploadimages'));

app.listen(3000, () => console.log('Backend Server running on port 3000'));