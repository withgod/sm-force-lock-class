/* confirmed only sqlite3 */

-- alter table history add cnt integer not null default 0;
create table history(
id integer primary key AUTOINCREMENT,
user_id text not null,
class_id integer not null default 0,
map text not null,
cnt integer not null default 0,
created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

create unique index uq_history on history(user_id, class_id);
