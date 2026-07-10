const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const ONESIGNAL_APP_ID = "bf6b1b1d-19f6-4782-8f9b-7c96a07be4ae";
const ONESIGNAL_REST_API_KEY = functions.params.defineSecret(
  "ONESIGNAL_REST_API_KEY"
);

async function sendOneSignalToNik({ nik, title, message, data }) {
  const response = await axios.post(
    "https://api.onesignal.com/notifications",
    {
      app_id: ONESIGNAL_APP_ID,
      include_aliases: {
        external_id: [nik],
      },
      target_channel: "push",
      headings: {
        en: title,
        id: title,
      },
      contents: {
        en: message,
        id: message,
      },
      data: data || {},
    },
    {
      headers: {
        Authorization: `Key ${ONESIGNAL_REST_API_KEY.value()}`,
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}

exports.kirimNotifikasiUser = functions.database
  .onValueCreated(
    {
      ref: "/notifikasi/{nik}/{notifId}",
      region: "asia-southeast1",
      secrets: [ONESIGNAL_REST_API_KEY],
    },
    async (event) => {
      const nik = event.params.nik;
      const notifId = event.params.notifId;
      const notif = event.data.val();

      if (!notif) return;
      if (notif.push_dikirim === true) return;

      const title = notif.judul || "TaniGo";
      const message = notif.pesan || "Ada informasi baru dari TaniGo.";

      try {
        const result = await sendOneSignalToNik({
          nik,
          title,
          message,
          data: {
            notif_id: notifId,
            tipe: notif.tipe || "",
            ...notif.data,
          },
        });

        await event.data.ref.update({
          push_dikirim: true,
          push_status: "terkirim",
          onesignal_result: result,
          push_sent_at: new Date().toISOString(),
        });
      } catch (error) {
        await event.data.ref.update({
          push_dikirim: false,
          push_status: "gagal",
          push_error: error.response?.data || error.message,
          push_failed_at: new Date().toISOString(),
        });
      }
    }
  );

exports.kirimPengumumanKeSemuaAnggota = functions.database
  .onValueCreated(
    {
      ref: "/pengumuman/{pengumumanId}",
      region: "asia-southeast1",
      secrets: [ONESIGNAL_REST_API_KEY],
    },
    async (event) => {
      const pengumuman = event.data.val();

      if (!pengumuman) return;
      if (pengumuman.status && pengumuman.status !== "aktif") return;

      const title = pengumuman.judul || "Pengumuman Baru";
      const message = pengumuman.isi || pengumuman.pesan || "Ada pengumuman baru dari admin.";

      const anggotaSnapshot = await admin.database().ref("anggota").get();

      if (!anggotaSnapshot.exists()) return;

      const externalIds = [];

      anggotaSnapshot.forEach((child) => {
        const nik = child.key;
        if (nik && nik !== "admin") {
          externalIds.push(nik);
        }
      });

      const chunks = [];
      for (let i = 0; i < externalIds.length; i += 2000) {
        chunks.push(externalIds.slice(i, i + 2000));
      }

      for (const chunk of chunks) {
        await axios.post(
          "https://api.onesignal.com/notifications",
          {
            app_id: ONESIGNAL_APP_ID,
            include_aliases: {
              external_id: chunk,
            },
            target_channel: "push",
            headings: {
              en: title,
              id: title,
            },
            contents: {
              en: message,
              id: message,
            },
            data: {
              tipe: "pengumuman_baru",
              pengumuman_id: event.params.pengumumanId,
            },
          },
          {
            headers: {
              Authorization: `Key ${ONESIGNAL_REST_API_KEY.value()}`,
              "Content-Type": "application/json",
            },
          }
        );
      }

      await event.data.ref.update({
        push_dikirim: true,
        push_sent_at: new Date().toISOString(),
      });
    }
  );