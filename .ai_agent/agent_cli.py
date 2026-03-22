from agent import GodotAIAgent
import os
import sys

if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    project_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    print("=" * 60)
    print("GODOT AI AGENT (Llama 3.1 + Function Calling)")
    print(f"Проект: {os.path.basename(project_path)}")
    print("=" * 60)
    print("Команды:")
    print("  /refresh - обновить контекст")
    print("  /context - статистика проекта")
    print("  /save    - сохранить историю")
    print("  /exit    - выход")
    print()
    
    try:
        agent = GodotAIAgent(project_path, server_url="http://192.168.1.106:11434")
        print("Агент инициализирован. Жду запросы...\n")
    except Exception as e:
        print(f"Ошибка инициализации: {e}")
        return
    
    while True:
        try:
            user_input = input("\nВы: ")
            
            if user_input == "/exit":
                print("Сохраняю и выхожу...")
                agent.save_memory()
                break
            elif user_input == "/refresh":
                print(agent.refresh_context())
                continue
            elif user_input == "/context":
                ctx = agent.conversation["project_context"]
                print(f"\n📊 Проект: {ctx['project_name']}")
                print(f"   Скриптов: {len(ctx['scripts'])}")
                print(f"   Сцен: {len(ctx['scenes'])}")
                print(f"   Файлов: {len(ctx['files'])}")
                continue
            elif user_input == "/save":
                agent.save_memory()
                print("Сохранено")
                continue
            elif user_input == "":
                continue
            
            print("\n🤖: ", end="")
            response = agent.ask(user_input)
            print(response)
            print()
            
        except KeyboardInterrupt:
            print("\n\nСохраняю и выхожу...")
            agent.save_memory()
            break
        except Exception as e:
            print(f"\nОшибка: {e}")

if __name__ == "__main__":
    main()