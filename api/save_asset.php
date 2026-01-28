<?php
/**
 * SLTB Board of Survey - Save Asset API
 * 
 * Place this file in: C:\xampp\htdocs\sltb\save_asset.php
 * Access URL: http://172.20.10.3/sltb/save_asset.php
 */

// Allow CORS from any origin
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = '127.0.0.1';
$port = 3307;
$dbname = 'sltb_survey';
$username = 'root';
$password = '';

try {
    // Connect to MySQL using PDO
    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);

    // Only accept POST requests
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode([
            'success' => false,
            'message' => 'Only POST method allowed'
        ]);
        exit();
    }

    // Get JSON data from request body
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);

    if (!$data) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid JSON data'
        ]);
        exit();
    }

    // Required field
    $newCode = $data['new_code'] ?? null;
    if (!$newCode) {
        echo json_encode([
            'success' => false,
            'message' => 'new_code is required'
        ]);
        exit();
    }

    // Check if asset exists
    $stmt = $pdo->prepare("SELECT id FROM assets WHERE new_code = ?");
    $stmt->execute([$newCode]);
    $exists = $stmt->fetch();

    if ($exists) {
        // Update existing asset
        $sql = "UPDATE assets SET 
            serial_no = :serial_no,
            description = :description,
            old_code = :old_code,
            book_balance = :book_balance,
            physical_balance = :physical_balance,
            excess = :excess,
            shortage = :shortage,
            remarks = :remarks,
            survey_status = :survey_status,
            image_path_1 = :image_path_1,
            image_path_2 = :image_path_2,
            image_path_3 = :image_path_3,
            entered_by = :entered_by,
            entered_date = :entered_date,
            verified_by = :verified_by,
            verified_date = :verified_date,
            verification_status = :verification_status,
            last_updated_by = :last_updated_by,
            last_updated_date = :last_updated_date,
            is_new_item = :is_new_item
            WHERE new_code = :new_code";
    } else {
        // Insert new asset
        $sql = "INSERT INTO assets (
            serial_no, description, old_code, new_code,
            book_balance, physical_balance, excess, shortage,
            remarks, survey_status,
            image_path_1, image_path_2, image_path_3,
            entered_by, entered_date, verified_by, verified_date,
            verification_status, last_updated_by, last_updated_date, is_new_item
        ) VALUES (
            :serial_no, :description, :old_code, :new_code,
            :book_balance, :physical_balance, :excess, :shortage,
            :remarks, :survey_status,
            :image_path_1, :image_path_2, :image_path_3,
            :entered_by, :entered_date, :verified_by, :verified_date,
            :verification_status, :last_updated_by, :last_updated_date, :is_new_item
        )";
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':serial_no' => $data['serial_no'] ?? null,
        ':description' => $data['description'] ?? null,
        ':old_code' => $data['old_code'] ?? null,
        ':new_code' => $newCode,
        ':book_balance' => $data['book_balance'] ?? 0,
        ':physical_balance' => $data['physical_balance'] ?? 0,
        ':excess' => $data['excess'] ?? 0,
        ':shortage' => $data['shortage'] ?? 0,
        ':remarks' => $data['remarks'] ?? null,
        ':survey_status' => $data['survey_status'] ?? null,
        ':image_path_1' => $data['image_path_1'] ?? null,
        ':image_path_2' => $data['image_path_2'] ?? null,
        ':image_path_3' => $data['image_path_3'] ?? null,
        ':entered_by' => $data['entered_by'] ?? null,
        ':entered_date' => $data['entered_date'] ?? null,
        ':verified_by' => $data['verified_by'] ?? null,
        ':verified_date' => $data['verified_date'] ?? null,
        ':verification_status' => $data['verification_status'] ?? 'pending',
        ':last_updated_by' => $data['last_updated_by'] ?? null,
        ':last_updated_date' => $data['last_updated_date'] ?? null,
        ':is_new_item' => $data['is_new_item'] ?? 0
    ]);

    echo json_encode([
        'success' => true,
        'message' => $exists ? 'Asset updated successfully' : 'Asset inserted successfully',
        'new_code' => $newCode
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
