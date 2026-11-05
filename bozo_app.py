import tkinter as tk
from tkinter import scrolledtext, messagebox, filedialog
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import backend

KEY_PREFIX = "Cooled-Bozo-Key-"
BG_IMAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bg_space.png")

class BozoExecutor:
    def __init__(self, root):
        self.root = root
        self.root.title("BOZO EXECUTER — SS EDITION — 2026")
        self.root.geometry("980x680")
        self.root.configure(bg="#02030a")
        self.port = None
        self.build_bg()
        self.build_ui()
        self.ask_key()

    def build_bg(self):
        # Tkinter cannot load PNG natively; convert to PPM at build time,
        # or use PIL. Keeping it minimal: place a tiled starfield canvas.
        self.canvas = tk.Canvas(self.root, bg="#02030a", highlightthickness=0)
        self.canvas.place(relx=0, rely=0, relwidth=1, relheight=1)
        self.overlay = tk.Frame(self.root, bg="#02030a")
        self.overlay.place(relx=0, rely=0, relwidth=1, relheight=1)

    def build_ui(self):
        top = tk.Frame(self.overlay, bg="#080820", height=52)
        top.pack(fill=tk.X, padx=8, pady=6)
        tk.Label(top, text="BOZO EXECUTER  //  SS EDITION",
                 fg="#00ffaa", bg="#080820",
                 font=("Courier", 18, "bold")).pack(side=tk.LEFT, padx=12)
        tk.Label(top, text="OFFICIAL 2026  •  NON COPYRIGHTED",
                 fg="#3366ff", bg="#080820",
                 font=("Courier", 9)).pack(side=tk.LEFT, padx=6)
        self.status = tk.Label(top, text="DISCONNECTED", fg="#ff3355",
                               bg="#080820", font=("Courier", 11, "bold"))
        self.status.pack(side=tk.RIGHT, padx=12)

        self.editor = scrolledtext.ScrolledText(
            self.overlay, bg="#05060f", fg="#00ffaa",
            insertbackground="#00ffaa", font=("Courier", 13),
            relief=tk.FLAT, borderwidth=0, wrap=tk.NONE
        )
        self.editor.pack(fill=tk.BOTH, expand=True, padx=12, pady=6)
        self.editor.insert("1.0", "-- Bozo Executer // paste Luau here\n")

        bar = tk.Frame(self.overlay, bg="#02030a")
        bar.pack(fill=tk.X, padx=12, pady=10)
        for label, cmd, colour in [
            ("INJECT", self.inject, "#00ffaa"),
            ("EXECUTE", self.execute, "#33aaff"),
            ("CLEAR", self.clear, "#ffaa33"),
            ("R6", self.r6, "#ff44aa"),
            ("SAVE", self.save, "#aa88ff"),
        ]:
            tk.Button(bar, text=label, command=cmd, bg="#111128",
                      fg=colour, font=("Courier", 11, "bold"),
                      relief=tk.FLAT, padx=20, pady=8,
                      activebackground=colour, activeforeground="#000"
                      ).pack(side=tk.LEFT, padx=4)
        self.stamp = tk.Label(self.overlay, text="[ OFFICIAL BOZO STAMP ]",
                              fg="#223355", bg="#02030a",
                              font=("Courier", 8, "bold"))
        self.stamp.pack(side=tk.BOTTOM, pady=6)

    def inject(self):
        port = backend.find_backend()
        if port:
            self.port = port
            self.status.config(text=f"CONNECTED :{port}", fg="#00ffaa")
            self.toast("Injected Bozo Executer!")
            return
        # no listener — try direct inject path (will fail on stock Mac)
        ok, msg = backend.try_inject("libOpiumware.dylib")
        self.status.config(text="NO BACKEND", fg="#ff3355")
        messagebox.showerror("Inject failed", msg)

    def execute(self):
        if not self.port:
            messagebox.showerror("Error", "Not injected.")
            return
        src = self.editor.get("1.0", tk.END).strip()
        if not src:
            return
        try:
            out = backend.send_script(self.port, src)
            if out:
                print(out)
        except Exception as e:
            messagebox.showerror("Execute error", str(e))

    def clear(self): self.editor.delete("1.0", tk.END)

    def r6(self):
        self.editor.insert(tk.END,
            '\npcall(function() game:GetService("ReplicatedStorage").R6 = true end)')

    def save(self):
        path = filedialog.asksaveasfilename(defaultextension=".lua",
                                            filetypes=[("Luau", "*.lua")])
        if path:
            with open(path, "w") as f:
                f.write(self.editor.get("1.0", tk.END))

    def ask_key(self):
        win = tk.Toplevel(self.root); win.title("Key Required")
        win.geometry("420x160"); win.configure(bg="#02030a")
        tk.Label(win, text="Cooled-Bozo-Key:", fg="#00ffaa",
                 bg="#02030a", font=("Courier", 12)).pack(pady=10)
        e = tk.Entry(win, bg="#111128", fg="#00ffaa",
                     insertbackground="#00ffaa", font=("Courier", 12))
        e.pack(pady=5, padx=22, fill=tk.X)
        def go():
            k = e.get().strip()
            if k.startswith(KEY_PREFIX) and len(k) == len(KEY_PREFIX) + 8:
                win.destroy()
            else:
                messagebox.showerror("Key Not Available!", "Invalid key.")
        tk.Button(win, text="OK", command=go, bg="#111128",
                  fg="#00ffaa").pack(pady=8)

    def toast(self, msg):
        t = tk.Toplevel(self.root); t.overrideredirect(True)
        t.geometry(f"+{self.root.winfo_rootx()+self.root.winfo_width()-300}"
                   f"+{self.root.winfo_rooty()+70}")
        tk.Label(t, text=msg, bg="#00ffaa", fg="#000",
                 font=("Courier", 11, "bold"), padx=12, pady=6).pack()
        self.root.after(2200, t.destroy)

if __name__ == "__main__":
    r = tk.Tk(); BozoExecutor(r); r.mainloop()
