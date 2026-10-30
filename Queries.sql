-- SBT-DF205 Case 1 (Android) - Queries.sql
-- Examiner: Mary-Joy Adewole, 2025/FWSD/11468
-- All statements were run read-only against COPIES of the evidence databases (extracts/..., copied with their -wal/-shm sidecars).
-- Timestamp units: Telephony sms.date, calls.date, Google Messages/WhatsApp/TextNow/Photos fields = milliseconds since 1970-01-01 UTC;
--                  Telephony pdu.date = seconds since 1970-01-01 UTC.  All conversions use datetime(x/1000,'unixepoch') or datetime(x,'unixepoch') (UTC).
-- Section 1 holds statements logged automatically by the q() helper (some appear twice because the block was re-run).
-- Section 2 holds statements run directly in the sqlite3 shell, and the non-SQL commands that produced the figures.

-- ===================== SECTION 1: statements logged by the q() helper =====================

-- Database: extracts/acc_ce_u0/accounts_ce.db
-- Purpose: Account names/types, user 0 (no secrets)
SELECT _id,name,type FROM accounts;

-- Database: extracts/acc_de_u0/accounts_de.db
-- Purpose: Account names/types, user 0 DE
SELECT _id,name,type FROM accounts;

-- Database: extracts/acc_de_u11/accounts_de.db
-- Purpose: Account names/types, user 11 DE
SELECT _id,name,type FROM accounts;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: SMS: all rows, ms epoch converted to UTC
SELECT _id,thread_id,address,type,read,date,datetime(date/1000,'unixepoch') AS date_utc,date_sent,substr(body,1,60) AS body FROM sms ORDER BY date;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: MMS: pdu rows, seconds epoch converted to UTC
SELECT _id,thread_id,msg_box,date,datetime(date,'unixepoch') AS date_utc,sub FROM pdu ORDER BY date;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: MMS: part rows (text and attachment references)
SELECT _id,mid,seq,ct,name,substr(text,1,60) AS text,_data FROM part;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: MMS addresses (137=From, 151=To)
SELECT msg_id,address,type FROM addr WHERE msg_id BETWEEN 1 AND 7 ORDER BY msg_id,type;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: Thread 17 recipient
SELECT t._id AS thread,t.message_count,t.recipient_ids,c.address FROM threads t LEFT JOIN canonical_addresses c ON c._id=t.recipient_ids WHERE t._id=17;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: Thread 17 reconstruction, SMS+MMS merged, UTC
SELECT 'sms' AS kind,_id,type AS dir_code,date/1000 AS epoch_s,datetime(date/1000,'unixepoch') AS utc,body AS content FROM sms WHERE thread_id=17 UNION ALL SELECT 'mms',p._id,p.msg_box,p.date,datetime(p.date,'unixepoch'),(SELECT group_concat(text,' ') FROM part WHERE mid=p._id AND ct='text/plain') FROM pdu p WHERE p.thread_id=17 ORDER BY epoch_s;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: SMS: five selected records, one-time codes redacted
SELECT _id,thread_id,address,type,read,date,datetime(date/1000,'unixepoch') AS utc,CASE WHEN body LIKE '%code%' OR body LIKE '%Please enter%' THEN '[verification code - redacted]' ELSE substr(body,1,60) END AS body FROM sms WHERE _id IN (4,8,15,21,25) ORDER BY date;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: MMS 1: header and parts
SELECT p._id,p.msg_box,p.m_type,p.text_only,p.date,datetime(p.date,'unixepoch') AS utc,pt._id AS part_id,pt.seq,pt.ct,substr(pt.text,1,50) AS text,pt._data FROM pdu p JOIN part pt ON pt.mid=p._id WHERE p._id=1;

-- Database: extracts/calllog/calllog.db
-- Purpose: Call log: all calls, ms epoch to UTC
SELECT _id,number,type,date,datetime(date/1000,'unixepoch') AS utc,duration,name,normalized_number FROM calls ORDER BY date;

-- Database: extracts/contacts/contacts2.db
-- Purpose: Contacts: raw contacts
SELECT _id,display_name,contact_id FROM raw_contacts;

-- Database: extracts/contacts/contacts2.db
-- Purpose: Contacts: number lookup
SELECT raw_contact_id,normalized_number FROM phone_lookup;

-- Database: extracts/calendar/calendar.db
-- Purpose: row count per table (SELECT count(*) FROM <table>, for each table in .tables)

-- Database: extracts/contacts/contacts2.db
-- Purpose: Contacts: raw contacts with owning account (corrected join)
SELECT r._id,a.account_name,a.account_type,r.deleted,r.contact_id FROM raw_contacts r LEFT JOIN accounts a ON a._id=r.account_id;

-- Database: extracts/contacts/contacts2.db
-- Purpose: Contacts: every stored phone number
SELECT d.raw_contact_id,d.data1 AS number FROM data d JOIN mimetypes m ON m._id=d.mimetype_id WHERE m.mimetype='vnd.android.cursor.item/phone_v2' ORDER BY d.raw_contact_id;

-- Database: extracts/calendar/calendar.db
-- Purpose: Calendar: owning account
SELECT _id,account_name,account_type,calendar_displayName FROM Calendars;

-- Database: extracts/telephony_main/mmssms.db
-- Purpose: SMS: five selected records, no verification codes
SELECT _id,thread_id,address,type,read,date,datetime(date/1000,'unixepoch') AS utc,substr(body,1,120) AS body FROM sms WHERE _id IN (17,20,21,24,25) ORDER BY date;

-- Database: extracts/calllog/calllog.db
-- Purpose: Call log: total rows and number presentation for blank-number calls
SELECT count(*) AS total_calls,sum(number='') AS blank_number FROM calls;

-- Database: extracts/calllog/calllog.db
-- Purpose: Call log: presentation flag, calls 1-5
SELECT _id,presentation,datetime(date/1000,'unixepoch') AS utc FROM calls WHERE _id<=5;

-- Database: extracts/bugle/bugle_db
-- Purpose: Google Messages: message count by protocol
SELECT message_protocol,count(*) AS n FROM messages GROUP BY 1;

-- Database: extracts/bugle/bugle_db
-- Purpose: Google Messages: messages with protocol, status, Telephony URI and times (ms epoch to UTC); code text redacted
SELECT m._id,m.conversation_id AS conv,m.message_protocol AS proto,m.message_status AS status,m.read,m.seen,m.sms_message_uri AS tele_uri,m.sent_timestamp,m.received_timestamp,datetime(m.received_timestamp/1000,'unixepoch') AS received_utc,CASE WHEN p.text LIKE '%code%' THEN '[code - redacted]' ELSE substr(p.text,1,50) END AS text FROM messages m LEFT JOIN parts p ON p.message_id=m._id ORDER BY m.received_timestamp;

-- Database: extracts/bugle/bugle_db
-- Purpose: Match Google Messages to Telephony SMS via sms_message_uri; compare times and read flags
ATTACH '/home/kali/SBT-DF205-C1/extracts/telephony_main/mmssms.db' AS t; SELECT m._id AS bugle_id,m.sms_message_uri,s._id AS tele_id,s.address,s.type AS tele_type,m.received_timestamp,s.date AS tele_date,m.received_timestamp=s.date AS date_equal,m.sent_timestamp,s.date_sent,m.read AS bugle_read,s.read AS tele_read,m.message_status FROM messages m JOIN t.sms s ON m.sms_message_uri='content://sms/'||s._id WHERE s._id IN (17,20,21,24,25) ORDER BY s._id;

-- Database: extracts/bugle/bugle_db
-- Purpose: Coverage: Google Messages rows linked to Telephony sms/pdu
ATTACH '/home/kali/SBT-DF205-C1/extracts/telephony_main/mmssms.db' AS t; SELECT (SELECT count(*) FROM messages) AS bugle_total,(SELECT count(*) FROM messages m JOIN t.sms s ON m.sms_message_uri='content://sms/'||s._id) AS sms_matched,(SELECT count(*) FROM t.sms) AS tele_sms,(SELECT count(*) FROM messages m JOIN t.pdu p ON m.sms_message_uri='content://mms/'||p._id) AS mms_matched,(SELECT count(*) FROM t.pdu) AS tele_pdu;

-- Database: extracts/bugle/bugle_db
-- Purpose: Google Messages rows with no Telephony counterpart
ATTACH '/home/kali/SBT-DF205-C1/extracts/telephony_main/mmssms.db' AS t; SELECT m._id,m.conversation_id AS conv,m.message_protocol AS proto,m.message_status AS status,m.sms_message_uri,datetime(m.received_timestamp/1000,'unixepoch') AS utc FROM messages m WHERE m.sms_message_uri IS NULL OR m.sms_message_uri NOT IN (SELECT 'content://sms/'||_id FROM t.sms UNION SELECT 'content://mms/'||_id FROM t.pdu);

-- Database: extracts/dialer_annotated/annotated_call_log.db
-- Purpose: Dialer: AnnotatedCallLog rows, blob columns excluded; ms epoch to UTC
SELECT _id,timestamp,datetime(timestamp/1000,'unixepoch') AS utc,raw_number,formatted_number,call_type,duration,presentation,is_read,new,features,is_voicemail_call,voicemail_uri IS NOT NULL AS has_vm_uri FROM AnnotatedCallLog ORDER BY timestamp;

-- Database: extracts/dialer_annotated/annotated_call_log.db
-- Purpose: Compare AOSP calllog.db with Dialer AnnotatedCallLog by timestamp, 2 s tolerance
ATTACH '/home/kali/SBT-DF205-C1/extracts/calllog/calllog.db' AS k; SELECT c._id AS aosp_id,datetime(c.date/1000,'unixepoch') AS aosp_utc,c.number AS aosp_number,c.type AS aosp_type,c.duration AS aosp_dur,a._id AS dialer_id,a.raw_number AS dialer_number,a.call_type AS dialer_type,a.duration AS dialer_dur,a.timestamp-c.date AS diff_ms FROM k.calls c LEFT JOIN AnnotatedCallLog a ON abs(a.timestamp-c.date)<2000 ORDER BY c.date;

-- Database: extracts/dialer_annotated/annotated_call_log.db
-- Purpose: Dialer rows with no AOSP counterpart
ATTACH '/home/kali/SBT-DF205-C1/extracts/calllog/calllog.db' AS k; SELECT a._id,datetime(a.timestamp/1000,'unixepoch') AS utc,a.raw_number,a.call_type,a.duration FROM AnnotatedCallLog a WHERE NOT EXISTS (SELECT 1 FROM k.calls c WHERE abs(a.timestamp-c.date)<2000);

-- Database: extracts/dialer_annotated/annotated_call_log.db
-- Purpose: Reproduce: Dialer lacks the two AOSP voicemail rows (counts and gaps)
ATTACH '/home/kali/SBT-DF205-C1/extracts/calllog/calllog.db' AS k; SELECT 'aosp_total' AS metric,count(*) AS n FROM k.calls UNION ALL SELECT 'dialer_total',count(*) FROM AnnotatedCallLog UNION ALL SELECT 'aosp_voicemail_type4',count(*) FROM k.calls WHERE type=4 UNION ALL SELECT 'dialer_type4',count(*) FROM AnnotatedCallLog WHERE call_type=4 UNION ALL SELECT 'aosp_not_in_dialer',count(*) FROM k.calls c WHERE NOT EXISTS (SELECT 1 FROM AnnotatedCallLog a WHERE abs(a.timestamp-c.date)<2000) UNION ALL SELECT 'dialer_not_in_aosp',count(*) FROM AnnotatedCallLog a WHERE NOT EXISTS (SELECT 1 FROM k.calls c WHERE abs(a.timestamp-c.date)<2000);

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: jid table
SELECT * FROM jid;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: validate status codes against receipt/read timestamps
SELECT key_from_me,status,count(*) AS n,sum(receipt_server_timestamp>0) AS srv,sum(receipt_device_timestamp>0) AS dev,sum(read_device_timestamp>0) AS rd,sum(played_device_timestamp>0) AS pl FROM messages GROUP BY 1,2 ORDER BY 1,2;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: all messages, ms epoch to UTC
SELECT _id,key_remote_jid,key_from_me,status,media_wa_type,timestamp,datetime(timestamp/1000,'unixepoch') AS utc,substr(data,1,70) AS text FROM messages ORDER BY timestamp;

-- Database: extracts/whatsapp_wa/wa.db
-- Purpose: WhatsApp wa.db: contacts (table present only via WAL)
SELECT jid,number,display_name,wa_name,is_whatsapp_user FROM wa_contacts;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: status vs receipt timestamps (NULL-safe)
SELECT key_from_me,status,count(*) AS n,sum(ifnull(receipt_server_timestamp,0)>0) AS server_rcpt,sum(ifnull(receipt_device_timestamp,0)>0) AS device_rcpt,sum(ifnull(read_device_timestamp,0)>0) AS read_rcpt,sum(ifnull(played_device_timestamp,0)>0) AS played FROM messages GROUP BY 1,2 ORDER BY 1,2;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: per-message receipt times (ms epoch to UTC)
SELECT _id,key_from_me AS me,status,media_wa_type AS type,datetime(timestamp/1000,'unixepoch') AS msg_utc,CASE WHEN receipt_server_timestamp>0 THEN datetime(receipt_server_timestamp/1000,'unixepoch') END AS server_utc,CASE WHEN receipt_device_timestamp>0 THEN datetime(receipt_device_timestamp/1000,'unixepoch') END AS device_utc,CASE WHEN read_device_timestamp>0 THEN datetime(read_device_timestamp/1000,'unixepoch') END AS read_utc FROM messages WHERE _id>=8 ORDER BY timestamp;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: media and location rows (no blobs)
SELECT _id,key_from_me AS me,media_wa_type AS type,media_mime_type,media_size,media_name,latitude,longitude FROM messages WHERE media_wa_type IN (1,5,16) AND _id>=9 ORDER BY _id;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: validate direction/type/state values by counts
SELECT message_direction,message_type,state,read,attach,count(*) AS n FROM messages GROUP BY 1,2,3,4,5 ORDER BY 1,2,3;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: all messages; date unit tested both ways; code-bearing text redacted
SELECT _id,contact_value,message_direction AS dir,message_type AS type,read,state,date,datetime(date/1000,'unixepoch') AS utc_if_ms,datetime(date,'unixepoch') AS utc_if_s,CASE WHEN lower(message_text) LIKE '%code%' OR lower(message_text) LIKE '%verif%' THEN '[redacted]' ELSE substr(message_text,1,70) END AS text FROM messages ORDER BY date;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: conversation row
SELECT _id,contact_value,contact_type,message_count FROM conversations;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: all messages; ms epoch to UTC; verification text and media links redacted
SELECT _id,contact_value,message_direction AS dir,message_type AS type,read,state,date,datetime(date/1000,'unixepoch') AS utc,CASE WHEN lower(message_text) LIKE '%code%' OR lower(message_text) LIKE '%verif%' THEN '[redacted]' WHEN message_text LIKE '%media.textnow.com%' THEN '[media link redacted]' ELSE substr(message_text,1,70) END AS text FROM messages ORDER BY date;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: rows 11-19 with direction, UTC time and receipts
SELECT _id,key_remote_jid AS jid,CASE key_from_me WHEN 1 THEN 'sent' ELSE 'received' END AS direction,status,media_wa_type AS type,datetime(timestamp/1000,'unixepoch') AS utc,CASE WHEN receipt_server_timestamp>0 THEN datetime(receipt_server_timestamp/1000,'unixepoch') END AS server_utc,CASE WHEN read_device_timestamp>0 THEN datetime(read_device_timestamp/1000,'unixepoch') END AS read_utc,substr(data,1,40) AS text FROM messages WHERE _id>=11 ORDER BY timestamp;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: contacts table, names and numbers only
SELECT _id,contact_value,contact_name,contact_type FROM contacts ORDER BY _id;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: all messages; ms epoch to UTC; verification text and media links redacted
SELECT _id,contact_value,message_direction AS dir,message_type AS type,read,state,date,datetime(date/1000,'unixepoch') AS utc,CASE WHEN lower(message_text) LIKE '%code%' OR lower(message_text) LIKE '%verif%' THEN '[redacted]' WHEN message_text LIKE '%media.textnow.com%' THEN '[media link redacted]' ELSE substr(message_text,1,70) END AS text FROM messages ORDER BY date;

-- Database: extracts/whatsapp_msgstore/msgstore.db
-- Purpose: WhatsApp: rows 11-19 with direction, UTC time and receipts
SELECT _id,key_remote_jid AS jid,CASE key_from_me WHEN 1 THEN 'sent' ELSE 'received' END AS direction,status,media_wa_type AS type,datetime(timestamp/1000,'unixepoch') AS utc,CASE WHEN receipt_server_timestamp>0 THEN datetime(receipt_server_timestamp/1000,'unixepoch') END AS server_utc,CASE WHEN read_device_timestamp>0 THEN datetime(read_device_timestamp/1000,'unixepoch') END AS read_utc,substr(data,1,40) AS text FROM messages WHERE _id>=11 ORDER BY timestamp;

-- Database: extracts/textnow/textnow_data.db
-- Purpose: TextNow: contacts table, names and numbers only
SELECT _id,contact_value,contact_name,contact_type FROM contacts ORDER BY _id;

-- Database: extracts/photos0/gphotos0.db
-- Purpose: Google Photos gphotos0.db: local_media rows for the four candidate files
SELECT _id,filename,folder_name,size_bytes,camera_model,latitude,longitude,capture_timestamp,utc_timestamp,timezone_offset,datetime(utc_timestamp/1000,'unixepoch') AS utc_if_ms FROM local_media WHERE filename IN ('IMG_20200209_132353.jpg','IMG_20200213_195030.jpg','IMG_20190917_082637.jpg','2020-02-09-125547759.mp4');

-- Database: extracts/photos0/gphotos0.db
-- Purpose: Google Photos: deleted/trash/hidden flags for the same files
SELECT l.filename,m.is_deleted,m.trash_timestamp,m.in_camera_folder,m.is_hidden,m.is_archived,m.is_favorite,m.has_local FROM local_media l LEFT JOIN media m ON m.dedup_key=l.dedup_key WHERE l.filename IN ('IMG_20200209_132353.jpg','IMG_20200213_195030.jpg','IMG_20190917_082637.jpg','2020-02-09-125547759.mp4');

-- ===================== SECTION 2: statements run directly (not logged by q) =====================

-- Database: telephony mmssms.db (each copy, original paths hashed first)
-- Purpose: row counts per copy (Task 4.1)
SELECT 'sms',count(*) FROM sms UNION ALL SELECT 'pdu',count(*) FROM pdu UNION ALL SELECT 'part',count(*) FROM part;

-- Database: calendar.db
-- Purpose: row count of every table (Task 4.4); executed as a shell loop over .tables
SELECT count(*) FROM <table>;

-- Database: bugle_db (Google Messages)
-- Purpose: table counts, schema and WAL comparison (Task 5.1)
SELECT 'messages',count(*) FROM messages UNION ALL SELECT 'conversations',count(*) FROM conversations UNION ALL SELECT 'parts',count(*) FROM parts UNION ALL SELECT 'participants',count(*) FROM participants;
.schema messages
.schema parts
.schema participants
.schema conversations
SELECT count(*) FROM messages;            -- run on the copy WITH -wal/-shm (36) and on a copy of the main file ALONE (35)
SELECT _id FROM messages;                 -- both result sets sorted and compared with comm: WAL-only _id = 39
SELECT name,seq FROM sqlite_sequence WHERE name IN ('messages','parts','conversations');   -- 39, 34, 15

-- Database: annotated_call_log.db (Google Dialer)
-- Purpose: table discovery, schema and row count (Task 5.2)
.tables
.schema AnnotatedCallLog
SELECT count(*) FROM AnnotatedCallLog;

-- Database: calllog.db
-- Purpose: AOSP rows 7-10 with voicemail_uri flag (Task 5.2)
SELECT _id,type,duration,datetime(date/1000,'unixepoch') AS utc,is_read,new,voicemail_uri IS NOT NULL AS has_vm_uri FROM calls WHERE _id IN (7,8,9,10);

-- Database: voicemail.db (Google Dialer)
-- Purpose: table discovery and greeting row count
.tables
SELECT count(*) FROM greeting;

-- Database: msgstore.db and wa.db (WhatsApp)
-- Purpose: WAL comparison, schema and content equality (Task 6.1/6.3)
SELECT group_concat(name,',') FROM pragma_table_info('messages');
SELECT count(*) FROM messages;            -- and chat_list, chat, jid, message (new schema: 0 rows); with WAL and main-only copy identical
SELECT _id,key_remote_jid,key_from_me,status,timestamp,data FROM messages ORDER BY _id;   -- output piped to md5sum, with and without WAL: identical
SELECT group_concat(name,',') FROM pragma_table_info('wa_contacts');
SELECT count(*) FROM wa_contacts;         -- 3 with WAL; table absent from main-only copy ("no such table")
SELECT _id,media_size,media_hash FROM messages WHERE _id IN (14,16);   -- compared with base64 SHA-256 of the two image files

-- Database: textnow_data.db
-- Purpose: structure and counts (Task 6.2)
.tables
SELECT count(*) FROM <table>;             -- messages 9, contacts 15, conversations 1; message_attributes, caller_id, blocked_contacts, groups, group_members 0
SELECT group_concat(name,',') FROM pragma_table_info('<table>');

-- Database: gphotos0.db and gphotos-1.db (Google Photos)
-- Purpose: WAL comparison and content equality (Task 7.2)
SELECT count(*) FROM media;               -- with WAL and main-only copy: identical (gphotos0 108; gphotos-1 26); same for local_media and remote_media
SELECT * FROM media ORDER BY _id;         -- output piped to md5sum with and without WAL: identical (media and local_media, both databases)
SELECT * FROM local_media ORDER BY _id;
SELECT group_concat(name,',') FROM pragma_table_info('<table>');

-- Cross-source participant search (Task 6.2); n = 9842032223, 9842352054, 9102697333
SELECT count(*) FROM participants WHERE normalized_destination LIKE '%n%' OR display_destination LIKE '%n%';   -- bugle_db
SELECT count(*) FROM canonical_addresses WHERE address LIKE '%n%';   -- Telephony
SELECT count(*) FROM data WHERE data1 LIKE '%n%';                    -- contacts2.db
SELECT count(*) FROM calls WHERE number LIKE '%n%';                  -- calllog.db

-- ===================== Non-SQL commands that produced figures =====================
-- sha256sum "original/Pixel 3.zip" | tee original/Pixel3.zip.sha256 ; sha256sum -c original/Pixel3.zip.sha256
-- grep -HE "^ro\.(product\.(vendor\.)?(manufacturer|model)|build\.version\.(release|security_patch)|build\.id|build\.fingerprint)=" <build.prop files>
-- grep -HoE '<setting id="[0-9]+" name="(device_name|bluetooth_name|airplane_mode_on|adb_enabled|development_settings_enabled|bluetooth_on|wifi_on|auto_time|auto_time_zone|install_non_market_apps)" value="[^"]*"' <settings_*.xml>
-- TZ=UTC exiftool -f -c '%.6f' -p '$FileName | taken $DateTimeOriginal $OffsetTimeOriginal | GPS $GPSPosition | GPS UTC $GPSDateStamp $GPSTimeStamp | $Make $Model | file mtime $FileModifyDate' <four media files>
-- base64( sha256sum <WhatsApp image> ) compared with messages.media_hash for rows 14 and 16 (python: hashlib, base64)
-- python3 (sqlite3, math, datetime): Maps place-record dump with secret-like columns omitted, epoch conversions, haversine distance to photo GPS
-- python3 (haversine): WhatsApp location rows 17-19 versus photo GPS
-- Secret filter: columns or text matching token|passw|secret|auth|session|bearer|apikey|cookie|oauth, or strings of 40+ token-like characters, are replaced by [omitted] / [redacted]; verification codes and media links are redacted.
