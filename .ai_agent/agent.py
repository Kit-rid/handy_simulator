import requests
import json
from pathlib import Path
from file_operator import GodotFileOperator
from datetime import datetime
import time

class GodotAIAgent:
    def __init__(self, project_path, server_url="http://192.168.1.106:11434"):
        self.project_path = Path(project_path)
        self.server_url = server_url
        self.model = "mistral:7b-instruct-q4_K_M"
        self.fs = GodotFileOperator(project_path)
        self.memory_file = self.project_path / ".ai_agent" / "memory.json"
        self.conversation = self.load_memory()
    
    def load_memory(self):
        if not self.memory_file.exists() or self.memory_file.stat().st_size == 0:
            return self.create_new_context()
        try:
            with open(self.memory_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data if isinstance(data, dict) else self.create_new_context()
        except:
            return self.create_new_context()
    
    def create_new_context(self):
        context = self.fs.get_project_context()
        return {
            "project_context": context,
            "messages": [{
                "role": "system",
                "content": f"""Ты AI-агент для Godot. Проект: {context['project_name']}

Правила:
1. Ты реально видишь файлы на диске
2. Используй list_directory() чтобы посмотреть папки
3. Используй read_file() чтобы прочитать код
4. Отвечай кратко и по делу"""
            }]
        }
    
    def list_directory(self, path="."):
        """Показать содержимое папки"""
        try:
            result, error = self.fs.list_directory(path)
            if error:
                return f"Ошибка: {error}"
            return result
        except Exception as e:
            return f"Ошибка: {e}"
    
    def read_file(self, path):
        """Прочитать файл"""
        try:
            content, error = self.fs.read_file(path)
            if error:
                return f"Ошибка: {error}"
            return f"Содержимое {path}:\n{content[:1000]}" + ("..." if len(content) > 1000 else "")
        except Exception as e:
            return f"Ошибка: {e}"
    
    def get_project_stats(self):
        """Статистика проекта"""
        try:
            context = self.fs.get_project_context()
            return f"""
Проект: {context['project_name']}
Сцен: {len(context['scenes'])}
Скриптов: {len(context['scripts'])}
Файлов: {len(context['files'])}
"""
        except Exception as e:
            return f"Ошибка: {e}"
    
    def ask(self, user_input):
        """Упрощенная версия без tool_calls"""
        
        # Проверяем подключение к серверу
        try:
            requests.get(f"{self.server_url}/api/tags", timeout=2)
        except:
            return "❌ Сервер Ollama не запущен. Запусти ollama serve на мощном ноуте."
        
        # Если спрашивают про проект - даем реальные данные
        if any(word in user_input.lower() for word in ["структур", "папк", "проект", "что есть", "файл", "видишь"]):
            stats = self.get_project_stats()
            root = self.list_directory(".")
            
            # Собираем сцены
            scenes = []
            for file in self.fs.project_root.rglob("*.tscn"):
                if not any(p.startswith('.') for p in file.parts):
                    scenes.append(str(file.relative_to(self.fs.project_root)))
            
            # Собираем скрипты
            scripts = []
            for file in self.fs.project_root.rglob("*.gd"):
                if not any(p.startswith('.') for p in file.parts):
                    scripts.append(str(file.relative_to(self.fs.project_root)))
            
            scene_text = "\n".join([f"  - {s}" for s in scenes[:10]])
            if len(scenes) > 10:
                scene_text += f"\n  ... и еще {len(scenes) - 10}"
            
            script_text = "\n".join([f"  - {s}" for s in scripts[:10]])
            if len(scripts) > 10:
                script_text += f"\n  ... и еще {len(scripts) - 10}"
            
            return f"""
📁 ПРОЕКТ: {self.fs.project_root.name}

📊 СТАТИСТИКА:
{stats}

📂 КОРНЕВАЯ ПАПКА:
{root}

🎮 СЦЕНЫ ({len(scenes)}):
{scene_text if scene_text else "  - Нет сцен"}

📜 СКРИПТЫ ({len(scripts)}):
{script_text if script_text else "  - Нет скриптов"}
"""
        
        # Обычный запрос к модели
        self.conversation["messages"].append({"role": "user", "content": user_input})
        
        try:
            response = requests.post(
                f"{self.server_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": self.conversation["messages"],
                    "stream": False,
                    "options": {
                        "temperature": 0.3,
                        "num_predict": 256
                    }
                },
                timeout=60
            )
            
            if response.status_code == 200:
                data = response.json()
                answer = data["message"]["content"]
                self.conversation["messages"].append({"role": "assistant", "content": answer})
                self.save_memory()
                return answer
            else:
                return f"❌ Ошибка сервера: {response.status_code}"
                
        except requests.exceptions.Timeout:
            return "⏰ Таймаут. Сервер не отвечает."
        except requests.exceptions.ConnectionError:
            return "🔌 Нет подключения к серверу."
        except Exception as e:
            return f"❌ Ошибка: {e}"
    
    def save_memory(self):
        self.memory_file.parent.mkdir(exist_ok=True)
        with open(self.memory_file, 'w', encoding='utf-8') as f:
            json.dump(self.conversation, f, ensure_ascii=False, indent=2)
    
    def refresh_context(self):
        context = self.fs.get_project_context()
        self.conversation["project_context"] = context
        self.save_memory()
        return "Контекст обновлен"