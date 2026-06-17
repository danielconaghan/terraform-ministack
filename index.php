<?php

require __DIR__ . '/vendor/autoload.php';

return function (array $event): array {
    return [
        'statusCode' => 200,
        'headers'    => ['Content-Type' => 'application/json'],
        'body'       => json_encode(['message' => 'Hello World']),
    ];
};
