# NULL POINTER 

> **"Złam zasady. Uciekaj z systemu."**

**Null Pointer** to logiczna gra logiczna 3D inspirowana klasyką *Bloxorz*, stworzona na Hackathon. Wcielasz się w anomalię danych, która próbuje uciec przed usunięciem z systemu, wykorzystując błędy w kodzie gry.

---

## 🏆 Temat Hackathonu: "Przełamać Barierę"

W naszej grze interpretujemy barierę jako **ograniczenia kodu i logiki gry a także własnej pomysłowości**.
* **Fizyczna bariera:** Ściany Firewall i przepaście (Void).
* **Przełamanie:** Mechanika **Glitch Walking**. Gracz musi zidentyfikować wizualne błędy w świecie i "wejść" w nie, zmuszając silnik gry do wyrenderowania mostu pod stopami. Łamiemy barierę strachu przed "spadnięciem w nicość".

---

## 🎮 Kluczowe Mechaniki

* **Fizyka Oparta na Raycastach:** Zrezygnowaliśmy z wbudowanego `Rigidbody`. Cały ruch klocka to nasz autorski system oparty na Raycastach dla pikselowej precyzji.
* **Perspektywa 3D:** Obrót kamery (`Q` / `E`) jest niezbędny, aby dostrzec ukryte przejścia i "naprawić" perspektywę.
* **World-Space Shaders:** Wszystkie efekty wizualne (Matrix Rain, Glitch Water) są liczone w przestrzeni świata, dzięki czemu tekstury płynnie przechodzą między klockami bez widocznych szwów.

---

## 🕹️ Sterowanie

| Klawisz | Akcja |
| :---: | :--- |
| **W, A, S, D** / Strzałki | Poruszanie klockiem (Turlanie) |
| **Q, E** | Obrót kamery (90 stopni) |
| **R** | Restart poziomu (Quick Reset) |

---

## 🛠️ Technologie

Projekt został zrealizowany w **100% w silniku Godot 4**.

* **Engine:** Godot 4.x
* **Język:** GDScript
* **Grafika:** Custom Shaders (.gdshader) - brak gotowych assetów graficznych dla efektów specjalnych.

---

## 👥 Zespół "Nowy Obóz"

Projekt stworzony w 24 godziny podczas hackathonu SCI 2025.

---
*Made with ❤️ and ☕ inside a Null Reference Exception.*
