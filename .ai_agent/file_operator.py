import os
import shutil
from pathlib import Path
from datetime import datetime
import json

class GodotFileOperator:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.backup_dir = self.project_root / ".ai_backups"
        self.backup_dir.mkdir(exist_ok=True)
        
    def get_project_context(self):
        """Собрать полную информацию о проекте"""
        context = {
            "project_name": self.project_root.name,
            "project_path": str(self.project_root.absolute()),
            "files": [],
            "scripts": [],
            "scenes": [],
            "folders": []
        }
        
        # Собираем уникальные папки
        folders = set()
        
        for file in self.project_root.rglob("*"):
            if file.is_file():
                rel_path = str(file.relative_to(self.project_root))
                
                # Пропускаем служебные папки
                if rel_path.startswith(".ai") or ".import" in rel_path or ".godot" in rel_path:
                    continue
                
                # Добавляем папку в набор
                folder = str(file.parent.relative_to(self.project_root))
                if folder != ".":
                    folders.add(folder)
                    
                file_info = {
                    "path": rel_path,
                    "name": file.name,
                    "extension": file.suffix,
                    "size": file.stat().st_size,
                    "modified": datetime.fromtimestamp(file.stat().st_mtime).isoformat()
                }
                
                context["files"].append(file_info)
                
                if rel_path.endswith(".gd"):
                    context["scripts"].append(rel_path)
                elif rel_path.endswith(".tscn"):
                    context["scenes"].append(rel_path)
                    
        context["folders"] = sorted(list(folders))
        return context
    
    def read_file(self, path):
        """Прочитать содержимое файла"""
        try:
            full_path = self.project_root / path
            if not full_path.exists():
                return None, f"Файл не найден: {path}"
            
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read()
            return content, None
        except Exception as e:
            return None, f"Ошибка чтения {path}: {e}"
    
    def write_file(self, path, content, backup=True):
        """Записать файл с автоматическим бекапом"""
        try:
            full_path = self.project_root / path
            
            # Создаем бекап если файл существует
            if backup and full_path.exists():
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_name = f"{path.replace('/', '_').replace('\\', '_')}_{timestamp}.bak"
                backup_path = self.backup_dir / backup_name
                shutil.copy2(full_path, backup_path)
            
            # Создаем папки если нужно
            full_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Записываем файл
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return True, f"Файл сохранен: {path}"
        except Exception as e:
            return False, f"Ошибка записи {path}: {e}"
    
    def list_directory(self, path="."):
        """Показать содержимое папки"""
        try:
            full_path = self.project_root / path
            if not full_path.exists():
                return None, f"Папка не найдена: {path}"
            if not full_path.is_dir():
                return None, f"Это не папка: {path}"
            
            items = []
            for item in full_path.iterdir():
                # Пропускаем служебные папки
                if item.name.startswith(".ai") or item.name == ".godot" or item.name == ".import":
                    continue
                
                rel_path = item.relative_to(self.project_root)
                
                if item.is_file():
                    size = item.stat().st_size
                    size_str = f"{size} B" if size < 1024 else f"{size/1024:.1f} KB"
                    items.append(f"[ФАЙЛ] {rel_path} ({size_str})")
                else:
                    items.append(f"[ПАПКА] {rel_path}/")
            
            return "\n".join(sorted(items)), None
        except Exception as e:
            return None, f"Ошибка чтения папки {path}: {e}"
    
    def search_files(self, pattern, file_types=None):
        """Поиск текста во всех файлах проекта"""
        results = []
        
        # По умолчанию ищем в .gd и .tscn
        if file_types is None:
            file_types = ['*.gd', '*.tscn']
        
        for ext in file_types:
            for file in self.project_root.rglob(ext):
                try:
                    # Пропускаем служебные папки
                    if any(p.startswith('.') for p in file.parts):
                        continue
                        
                    with open(file, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                    
                    rel_path = file.relative_to(self.project_root)
                    
                    for i, line in enumerate(lines, 1):
                        if pattern.lower() in line.lower():
                            line_clean = line.strip()
                            results.append({
                                "file": str(rel_path),
                                "line": i,
                                "content": line_clean,
                                "preview": f"{rel_path}:{i}  {line_clean[:100]}"
                            })
                except (UnicodeDecodeError, PermissionError):
                    continue
                except Exception as e:
                    print(f"Ошибка обработки {file}: {e}")
                    continue
        
        return results[:50]
    
    def search_files_text(self, pattern):
        """Упрощенный текстовый вывод для модели"""
        results = self.search_files(pattern)
        if not results:
            return f"Ничего не найдено по запросу '{pattern}'"
        
        output = [f"Найдено {len(results)} совпадений с '{pattern}':"]
        for r in results[:20]:
            output.append(f"  {r['preview']}")
        
        if len(results) > 20:
            output.append(f"  ... и еще {len(results) - 20} совпадений")
        
        return "\n".join(output)
    
    def get_file_tree(self, max_depth=3):
        """Получить структуру проекта в виде дерева"""
        def _build_tree(path, depth):
            if depth > max_depth:
                return ["  " * depth + "└── ..."]
            
            lines = []
            items = sorted(path.iterdir(), key=lambda x: (not x.is_dir(), x.name))
            
            for i, item in enumerate(items):
                # Пропускаем служебные папки
                if item.name.startswith(".ai") or item.name == ".godot" or item.name == ".import":
                    continue
                    
                prefix = "├── " if i < len(items) - 1 else "└── "
                rel_path = item.relative_to(self.project_root)
                
                if item.is_dir():
                    lines.append("  " * depth + prefix + f"{item.name}/")
                    lines.extend(_build_tree(item, depth + 1))
                else:
                    size = item.stat().st_size
                    size_str = f"{size} B" if size < 1024 else f"{size/1024:.1f} KB"
                    lines.append("  " * depth + prefix + f"{item.name} ({size_str})")
            
            return lines
        
        try:
            tree_lines = [f"Проект: {self.project_root.name}/"]
            tree_lines.extend(_build_tree(self.project_root, 0))
            return "\n".join(tree_lines[:100])  # Ограничиваем вывод
        except Exception as e:
            return f"Ошибка построения дерева: {e}"
    
    def create_script(self, path, content):
        """Создать GDScript файл"""
        if not path.endswith(".gd"):
            path += ".gd"
        return self.write_file(path, content)
    
    def get_file_info(self, path):
        """Получить информацию о файле"""
        try:
            full_path = self.project_root / path
            if not full_path.exists():
                return None, f"Файл не найден: {path}"
            
            stat = full_path.stat()
            info = {
                "path": str(full_path.relative_to(self.project_root)),
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
                "is_dir": full_path.is_dir()
            }
            return info, None
        except Exception as e:
            return None, f"Ошибка получения информации: {e}"
    
    def delete_file(self, path, backup=True):
        """Удалить файл с бекапом"""
        try:
            full_path = self.project_root / path
            if not full_path.exists():
                return False, f"Файл не найден: {path}"
            
            if backup:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_name = f"DELETED_{path.replace('/', '_').replace('\\', '_')}_{timestamp}.bak"
                backup_path = self.backup_dir / backup_name
                shutil.copy2(full_path, backup_path)
            
            if full_path.is_dir():
                shutil.rmtree(full_path)
                return True, f"Папка удалена: {path}"
            else:
                full_path.unlink()
                return True, f"Файл удален: {path}"
                
        except Exception as e:
            return False, f"Ошибка удаления {path}: {e}"
    
    def move_file(self, source, destination, backup=True):
        """Переместить/переименовать файл"""
        try:
            src_path = self.project_root / source
            dst_path = self.project_root / destination
            
            if not src_path.exists():
                return False, f"Исходный файл не найден: {source}"
            
            if backup and dst_path.exists():
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_name = f"MOVED_{destination.replace('/', '_').replace('\\', '_')}_{timestamp}.bak"
                backup_path = self.backup_dir / backup_name
                shutil.copy2(dst_path, backup_path)
            
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src_path), str(dst_path))
            
            return True, f"Файл перемещен: {source} -> {destination}"
            
        except Exception as e:
            return False, f"Ошибка перемещения: {e}"