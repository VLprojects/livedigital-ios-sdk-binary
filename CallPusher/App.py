from cProfile import label
import tkinter as tk
from tkinter import ttk, filedialog
import webbrowser
import cv2
from PIL import Image, ImageTk
import json
import httpx
import os

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("livedigital call pusher")
        self.minsize(700, 200)
        self._build_ui()
        self._stop_camera()

    # ---------- UI ----------

    def _build_ui(self):
        main = ttk.Frame(self, padding=10)
        main.pack(fill="both", expand=True)
        apnsHosts = ["https://api.sandbox.push.apple.com", "https://api.push.apple.com"]
        self.bundleId_var = tk.StringVar(value= "pro.vlprojects.livedigital-sdk-example")
        self.apnsHost_var = tk.StringVar(value = apnsHosts[0])
        self.certFile_var = tk.StringVar(value = "./apns_cert.pem")
        self.pkeyFile_var = tk.StringVar(value = "./apns_key.pem")
        self.deviceToken_var = tk.StringVar(value= "")
        self.roomAlias_var = tk.StringVar(value= "q3_5V3uwik")
        self._text_row(main, "Bundle ID:", self.bundleId_var).pack(fill="x", pady=5)
        self._combo_row(main, "APNS Host:", apnsHosts, self.apnsHost_var).pack(fill="x", pady=5)
        self._file_row(main, "Certificate file:", self.certFile_var).pack(fill="x", pady=5)
        self._file_row(main, "Private key file:", self.pkeyFile_var).pack(fill="x", pady=5)
        self._token_row(main, "Device token:", self.deviceToken_var).pack(fill="x", pady=5)
        self._text_row(main, "Room alias:", self.roomAlias_var).pack(fill="x", pady=5)
        self._link_row(main, "Room link:", self.roomAlias_var).pack(fill="x", pady=5)
        self.send_btn = ttk.Button(main, text="Start call", command=self._send_push)
        self.send_btn.pack(pady=10)

    def _link_row(self, parent, label, var):
        linkVariable = tk.StringVar()
        def update_link(*_):
            linkVariable.set(
                f"https://edu.livedigital.space/room/{self.roomAlias_var.get()}"
            )
        self.roomAlias_var.trace_add("write", update_link)
        update_link()
        frame = ttk.Frame(parent)
        ttk.Label(frame, text=label).pack(side="left")
        link_label = ttk.Label(frame, textvariable=linkVariable, cursor="hand2", font=("TkDefaultFont", 9))
        link_label.bind("<Button-1>", lambda e: webbrowser.open(linkVariable.get()))
        link_label.bind("<Enter>", lambda e: link_label.configure(font=("TkDefaultFont", 9, "underline")))
        link_label.bind("<Leave>", lambda e: link_label.configure(font=("TkDefaultFont", 9)))
        link_label.pack(side="left", fill="x", expand=True)
        return frame

    def _text_row(self, parent, label, var):
        frame = ttk.Frame(parent)
        ttk.Label(frame, text=label).pack(side="top", expand=True, anchor="w")
        ttk.Entry(frame, textvariable=var).pack(side="left", fill="x", expand=True)
        return frame

    def _combo_row(self, parent, label, values, var):
        frame = ttk.Frame(parent)
        ttk.Label(frame, text=label).pack(side="top", expand=True, anchor="w")
        combo = ttk.Combobox(
            frame,
            textvariable=var,
            values=values,
            state="readonly"
        )
        combo.pack(side="left", fill="x", expand=True)
        return frame

    def _file_row(self, parent, label, var):
        frame = ttk.Frame(parent)
        ttk.Label(frame, text=label).pack(side="top", expand=True, anchor="w")
        ttk.Entry(frame, textvariable=var).pack(side="left", fill="x", expand=True)
        ttk.Button(
            frame,
            text="Browse",
            command=lambda: self._choose_file(var)
        ).pack(side="left")
        return frame

    def _choose_file(self, var):
        path = filedialog.askopenfilename()
        if path:
            var.set(path)

    def _token_row(self, parent, label, var):
        frame = ttk.Frame(parent)
        ttk.Label(frame, text=label).pack(side="top", expand=True, anchor="w")
        row = ttk.Frame(frame)
        row.pack(side="top", fill="x")
        ttk.Entry(row, textvariable=var).pack(side="left", fill="x", expand=True)
        self.toggle_btn = ttk.Button(row, command=self._toggle_camera)
        self.toggle_btn.pack(side="left")
        self.preview_label = ttk.Label(frame)
        self.preview_label.pack(side="bottom", pady=8)
        # preview is initially hidden
        self.preview_label.pack_forget()
        return frame

    # ---------- Camera ----------

    def _toggle_camera(self):
        if self.camera_running:
            self._stop_camera()
        else:
            self._start_camera()

    def _start_camera(self):
        self.qr_detector = cv2.QRCodeDetector()
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            self.cap = None
            return
        self.camera_running = True
        self.toggle_btn.config(text="Stop Camera")
        self.preview_label.pack(expand=True, pady=10)
        self._update_frame()

    def _stop_camera(self):
        self.camera_running = False
        self.toggle_btn.config(text="Read from QR code")
        if hasattr(self, 'cap') and self.cap is not None:
            self.cap.release()
            self.cap = None
        if hasattr(self, 'qr_detector') and self.qr_detector is not None:
            self.qr_detector = None
        self.preview_label.config(image="")
        self.preview_label.pack_forget()

    def _update_frame(self):
        if not self.camera_running or not self.cap or not self.cap.isOpened():
            return
        ret, frame = self.cap.read()
        if not ret:
            self.after(30, self._update_frame)
            return
        data, _, _ = self.qr_detector.detectAndDecode(frame)
        if data:
            self.deviceToken_var.set(data)
            self._stop_camera()
            return
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        h, w, _ = frame.shape
        target_h = 300
        target_w = int(w * target_h / h)
        img = Image.fromarray(frame).resize((target_w, target_h))
        imgtk = ImageTk.PhotoImage(img)
        self.preview_label.imgtk = imgtk
        self.preview_label.config(image=imgtk)
        self.after(30, self._update_frame)

    # ---------- APNS ----------

    def _send_push(self):
        cert_path = self.certFile_var.get()
        key_path = self.pkeyFile_var.get()
        if not cert_path or not key_path:
            tk.messagebox.showerror("Error", f"Certificate file and private key file must be set")
            raise ValueError("Certificate file and private key file must be set")
        if not os.path.isfile(cert_path):
            tk.messagebox.showerror("Error", f"Certificate file not found: {cert_path}")
            raise FileNotFoundError(f"Certificate file not found: {cert_path}")
        if not os.path.isfile(key_path):
            tk.messagebox.showerror("Error", f"Private key file not found: {key_path}")
            raise FileNotFoundError(f"Private key file not found: {key_path}")
        certs = (cert_path, key_path)
        with httpx.Client(http2=True, cert=certs) as client:
            payload = {
                "aps": {
                    "content-available": 1
                },
                "caller": f"Room {self.roomAlias_var.get()}",
                "roomAlias": self.roomAlias_var.get(),
            }
            response = client.post(
                f"{self.apnsHost_var.get()}/3/device/{self.deviceToken_var.get()}",
                headers={
                    "apns-topic": f"{self.bundleId_var.get()}.voip",
                    "apns-push-type": "voip",
                    "apns-priority": "10",
                    "apns-expiration": "0",
                    "content-type": "application/json",
                },
                content=json.dumps(payload)
            )
            print(response.status_code, response.text)
            if response.is_error:
                tk.messagebox.showerror("Error", f"Failed to send push notification:\n{response.status_code} {response.text}")

    def destroy(self):
        if hasattr(self, 'cap') and self.cap is not None:
            self.cap.release()
            self.cap = None
        super().destroy()

if __name__ == "__main__":
    App().mainloop()
