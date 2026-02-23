<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'METHOD_NOT_ALLOWED']);
    exit;
}

$raw = file_get_contents('php://input');
$payload = json_decode($raw ?: '', true);
if (!is_array($payload)) {
    http_response_code(400);
    echo json_encode(['error' => 'INVALID_JSON']);
    exit;
}

$endpoint = (string)($payload['endpoint'] ?? '');
$body = $payload['body'] ?? null;
if (!is_array($body)) {
    http_response_code(400);
    echo json_encode(['error' => 'INVALID_BODY']);
    exit;
}

$pathByEndpoint = [
    'responses' => '/v1/responses',
    'chat_completions' => '/v1/chat/completions',
];
if (!isset($pathByEndpoint[$endpoint])) {
    http_response_code(400);
    echo json_encode(['error' => 'INVALID_ENDPOINT']);
    exit;
}

$envPath = '/etc/lector-escrituraapp/openai.env';
$env = is_file($envPath) ? parse_ini_file($envPath, false, INI_SCANNER_RAW) : false;
if (!is_array($env)) {
    http_response_code(500);
    echo json_encode(['error' => 'SERVER_ENV_NOT_FOUND']);
    exit;
}

$apiKey = trim((string)($env['OPENAI_API_KEY'] ?? ''));
$defaultModel = trim((string)($env['OPENAI_MODEL'] ?? 'gpt-4o-mini'));
if ($apiKey === '') {
    http_response_code(500);
    echo json_encode(['error' => 'SERVER_API_KEY_MISSING']);
    exit;
}

if (!isset($body['model']) || trim((string)$body['model']) === '') {
    $body['model'] = $defaultModel === '' ? 'gpt-4o-mini' : $defaultModel;
}

$ch = curl_init('https://api.openai.com' . $pathByEndpoint[$endpoint]);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $apiKey,
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode($body, JSON_UNESCAPED_UNICODE),
    CURLOPT_TIMEOUT => 90,
]);

$responseBody = curl_exec($ch);
if ($responseBody === false) {
    $error = curl_error($ch);
    curl_close($ch);
    http_response_code(502);
    echo json_encode(['error' => 'UPSTREAM_REQUEST_FAILED', 'detail' => $error]);
    exit;
}

$status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
http_response_code($status > 0 ? $status : 502);
echo $responseBody;
