<?php

namespace Tests\Feature;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class RemoteApiSmokeTest extends TestCase
{
    private function remoteClient(): PendingRequest
    {
        $baseUrl = rtrim((string) config('services.remote_api.base_url', ''), '/');

        if ($baseUrl === '') {
            $this->markTestSkipped('REMOTE_API_BASE_URL is not configured.');
        }

        return Http::baseUrl($baseUrl)
            ->withOptions([
                'timeout' => (int) config('services.remote_api.timeout', 10),
                'http_errors' => false,
                'verify' => filter_var(config('services.remote_api.verify_ssl', true), FILTER_VALIDATE_BOOL),
            ]);
    }

    public static function endpointProvider(): array
    {
        return [
            'general settings' => ['GET', 'general-setting', [200]],
            'countries' => ['GET', 'get-countries', [200]],
            'faq' => ['GET', 'faq', [200]],
            'policies' => ['GET', 'policies', [200]],
            'zones' => ['GET', 'zones', [200]],
            'user login validation' => ['POST', 'login', [401, 422]],
            'driver login validation' => ['POST', 'driver/login', [401, 422]],
            'user ride list requires auth' => ['GET', 'ride/list', [401]],
            'driver ride list requires auth' => ['GET', 'driver/rides/list', [401]],
        ];
    }

    #[DataProvider('endpointProvider')]
    public function test_remote_endpoint(string $method, string $uri, array $expectedStatuses): void
    {
        $client = $this->remoteClient();

        try {
            $response = $client->send($method, ltrim($uri, '/'));
        } catch (ConnectionException $exception) {
            $this->markTestSkipped('Remote API not reachable: ' . $exception->getMessage());
        }

        $status = $response->status();

        $this->assertContains(
            $status,
            $expectedStatuses,
            sprintf('Unexpected status %d for %s %s. Body: %s', $status, $method, $uri, $response->body())
        );

        if ($status >= 200 && $status < 300) {
            $this->assertTrue(
                $this->isJson($response->body()),
                sprintf('Expected JSON payload for %s %s but received: %s', $method, $uri, $response->body())
            );
        }
    }

    private function isJson(string $payload): bool
    {
        if ($payload === '') {
            return false;
        }

        json_decode($payload);

        return json_last_error() === JSON_ERROR_NONE;
    }
}