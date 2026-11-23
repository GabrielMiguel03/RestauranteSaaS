<?php
declare(strict_types=1);

function db(): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $config = require dirname(__DIR__) . '/config.php';
    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=%s', $config['db']['host'], $config['db']['name'], $config['db']['charset']);
    $pdo = new PDO($dsn, $config['db']['user'], $config['db']['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    return $pdo;
}

function json_response(array $data, int $status = 200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function input(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw ?: '{}', true);
    return is_array($data) ? $data : $_POST;
}

function require_login(): array {
    if (session_status() !== PHP_SESSION_ACTIVE) session_start();
    if (empty($_SESSION['user'])) json_response(['error' => 'Não autenticado.'], 401);
    return $_SESSION['user'];
}

function require_permission(array $user, string $action, string $method, array $query = []): void {
    $role = $user['perfil'] ?? 'operacional';
    if (in_array($role, ['admin', 'gestor'], true)) return;
    $allowed = [
        'cozinha' => ['dashboard','lookups','recipes','recipe_versions','waste','waste_report','report_history','report_history_item','production','production_detail','production_confirm','buffet','breakages','search'],
        'compras' => ['dashboard','lookups','products','suppliers','purchases','purchase_detail','purchase_receive','price_history','stock','inventory','inventory_detail','inventory_count','inventory_approve','search'],
        'operacional' => ['dashboard','lookups','waste','buffet','breakages','search'],
    ];
    if (!in_array($action, $allowed[$role] ?? [], true)) json_response(['error'=>'Seu perfil não tem permissão para esta ação.'],403);
    if ($role==='cozinha' && $action==='recipes' && $method!=='GET') json_response(['error'=>'Seu perfil pode apenas consultar fichas técnicas.'],403);
    if ($role==='operacional' && $action==='search' && ($query['type']??'')!=='products') json_response(['error'=>'Seu perfil só pode pesquisar produtos.'],403);
    if (in_array($action,['report_history','report_history_item'],true) && $method!=='GET') json_response(['error'=>'Seu perfil não pode salvar relatórios.'],403);
}

function verify_csrf(): void {
    $expected = (string)($_SESSION['csrf_token'] ?? '');
    $provided = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    if ($expected==='' || $provided==='' || !hash_equals($expected,$provided)) json_response(['error'=>'Sessão expirou ou token de segurança inválido. Atualize a página e tente novamente.'],419);
}

function audit(int $userId, string $action, string $entity, ?int $entityId = null, array $details = []): void {
    $stmt = db()->prepare('INSERT INTO auditoria (usuario_id, acao, entidade, entidade_id, detalhes) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$userId, $action, $entity, $entityId, json_encode($details, JSON_UNESCAPED_UNICODE)]);
}
