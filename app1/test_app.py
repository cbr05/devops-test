"""
Testes unitários para App1 - Python FastAPI
"""
import sys
import os
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import redis as redis_lib
import app as app_module
from fastapi.testclient import TestClient


class TestTextEndpoint(unittest.TestCase):

    def setUp(self):
        self.redis_mock = MagicMock()
        self.patcher = patch.object(app_module, "redis_client", self.redis_mock)
        self.patcher.start()
        self.client = TestClient(app_module.app)

    def tearDown(self):
        self.patcher.stop()

    def test_texto_fixo_cache_miss(self):
        """Retorna texto fixo e grava no cache quando cache está vazio."""
        self.redis_mock.get.return_value = None

        response = self.client.get("/text")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["source"], "computed")
        self.assertFalse(data["cached"])
        self.assertIn("App 1", data["text"])
        self.redis_mock.setex.assert_called_once_with("app1:text", 10, data["text"])

    def test_texto_fixo_cache_hit(self):
        """Retorna resposta do cache quando disponível, sem gravar novamente."""
        self.redis_mock.get.return_value = "texto vindo do cache"

        response = self.client.get("/text")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["source"], "cache")
        self.assertTrue(data["cached"])
        self.assertEqual(data["text"], "texto vindo do cache")
        self.redis_mock.setex.assert_not_called()

    def test_horario_cache_miss(self):
        """Retorna horário atual e grava no cache quando cache está vazio."""
        self.redis_mock.get.return_value = None

        response = self.client.get("/time")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["source"], "computed")
        self.assertFalse(data["cached"])
        self.assertIn("time", data)
        self.redis_mock.setex.assert_called_once()
        key_usado = self.redis_mock.setex.call_args[0][0]
        self.assertEqual(key_usado, "app1:time")

    def test_horario_cache_hit(self):
        """Retorna horário do cache quando disponível."""
        horario_cached = "2024-01-15T10:30:00"
        self.redis_mock.get.return_value = horario_cached

        response = self.client.get("/time")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["source"], "cache")
        self.assertTrue(data["cached"])
        self.assertEqual(data["time"], horario_cached)
        self.redis_mock.setex.assert_not_called()

    def test_cache_ttl_e_10_segundos(self):
        """Verifica que o TTL de gravação no cache é de 10 segundos."""
        self.redis_mock.get.return_value = None

        self.client.get("/text")

        _, ttl, _ = self.redis_mock.setex.call_args[0]
        self.assertEqual(ttl, 10)


class TestHealthEndpoint(unittest.TestCase):

    def setUp(self):
        self.redis_mock = MagicMock()
        self.patcher = patch.object(app_module, "redis_client", self.redis_mock)
        self.patcher.start()
        self.client = TestClient(app_module.app)

    def tearDown(self):
        self.patcher.stop()

    def test_health_redis_disponivel(self):
        """Health check retorna redis healthy quando conexão funciona."""
        self.redis_mock.ping.return_value = True

        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["redis"], "healthy")
        self.assertEqual(data["app"], "app1")

    def test_health_redis_indisponivel(self):
        """App continua healthy mesmo com Redis indisponível."""
        self.redis_mock.ping.side_effect = redis_lib.RedisError("connection refused")

        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["redis"], "unhealthy")


class TestRootEndpoint(unittest.TestCase):

    def setUp(self):
        self.redis_mock = MagicMock()
        self.patcher = patch.object(app_module, "redis_client", self.redis_mock)
        self.patcher.start()
        self.client = TestClient(app_module.app)

    def tearDown(self):
        self.patcher.stop()

    def test_root_retorna_endpoints(self):
        """Rota raiz lista os endpoints disponíveis."""
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("app", data)
        self.assertIn("endpoints", data)
        self.assertIn("/text", data["endpoints"].values())
        self.assertIn("/time", data["endpoints"].values())
        self.assertIn("/health", data["endpoints"].values())


class TestClearCacheEndpoint(unittest.TestCase):

    def setUp(self):
        self.redis_mock = MagicMock()
        self.patcher = patch.object(app_module, "redis_client", self.redis_mock)
        self.patcher.start()
        self.client = TestClient(app_module.app)

    def tearDown(self):
        self.patcher.stop()

    def test_clear_cache_deleta_chaves_da_app(self):
        """Limpar cache deleta apenas as chaves desta aplicação."""
        self.redis_mock.delete.return_value = 2

        response = self.client.get("/cache/clear")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.redis_mock.delete.assert_called_once_with("app1:text", "app1:time")

    def test_clear_cache_erro_redis(self):
        """Erro de Redis é retornado com status error."""
        self.redis_mock.delete.side_effect = redis_lib.RedisError("timeout")

        response = self.client.get("/cache/clear")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "error")


if __name__ == "__main__":
    unittest.main()
