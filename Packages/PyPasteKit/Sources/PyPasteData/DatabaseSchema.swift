public enum DatabaseSchema {
    public static let currentVersion = 5

    public static let migrations: [DatabaseMigration] = [
        DatabaseMigration(
            version: 1,
            statements: [
                """
                CREATE TABLE IF NOT EXISTS clips (
                    id TEXT NOT NULL PRIMARY KEY,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL,
                    content_kind TEXT NOT NULL,
                    display_title TEXT NOT NULL,
                    searchable_text TEXT,
                    source_bundle_id TEXT,
                    source_application_name TEXT,
                    content_hash TEXT NOT NULL,
                    is_favorite INTEGER NOT NULL DEFAULT 0,
                    is_sensitive INTEGER NOT NULL DEFAULT 0,
                    is_deleted INTEGER NOT NULL DEFAULT 0,
                    deleted_at REAL,
                    copy_count INTEGER NOT NULL DEFAULT 1,
                    primary_blob_path TEXT,
                    metadata_json TEXT
                );
                """,
                """
                CREATE TABLE IF NOT EXISTS clip_representations (
                    id TEXT NOT NULL PRIMARY KEY,
                    clip_id TEXT NOT NULL,
                    uti TEXT NOT NULL,
                    storage_type TEXT NOT NULL,
                    inline_data BLOB,
                    blob_path TEXT,
                    byte_count INTEGER NOT NULL DEFAULT 0,
                    checksum TEXT,
                    FOREIGN KEY (clip_id) REFERENCES clips(id) ON DELETE CASCADE
                );
                """,
            ]
        ),
        DatabaseMigration(
            version: 2,
            statements: [
                "CREATE INDEX IF NOT EXISTS clips_created_at_index ON clips(created_at DESC);",
                "CREATE INDEX IF NOT EXISTS clips_content_hash_index ON clips(content_hash);",
                """
                CREATE INDEX IF NOT EXISTS clip_representations_clip_id_index
                ON clip_representations(clip_id);
                """,
            ]
        ),
        DatabaseMigration(
            version: 3,
            statements: [
                "ALTER TABLE clips ADD COLUMN last_used_at REAL;",
                "ALTER TABLE clips ADD COLUMN character_count INTEGER;",
                "ALTER TABLE clips ADD COLUMN line_count INTEGER;",
                """
                ALTER TABLE clip_representations
                ADD COLUMN item_index INTEGER NOT NULL DEFAULT 0;
                """,
                """
                ALTER TABLE clip_representations
                ADD COLUMN representation_index INTEGER NOT NULL DEFAULT 0;
                """,
                """
                CREATE INDEX IF NOT EXISTS clips_last_used_at_index
                ON clips(last_used_at DESC);
                """,
            ]
        ),
        DatabaseMigration(
            version: 4,
            statements: [
                "ALTER TABLE clips ADD COLUMN sort_rank INTEGER NOT NULL DEFAULT 0;",
                """
                WITH ranked_clips AS (
                    SELECT id,
                           COUNT(*) OVER () - ROW_NUMBER() OVER (
                               ORDER BY COALESCE(last_used_at, updated_at) DESC,
                                        created_at DESC,
                                        id ASC
                           ) + 1 AS rank
                    FROM clips
                    WHERE is_deleted = 0
                )
                UPDATE clips
                SET sort_rank = (
                    SELECT rank
                    FROM ranked_clips
                    WHERE ranked_clips.id = clips.id
                )
                WHERE is_deleted = 0;
                """,
                """
                CREATE INDEX IF NOT EXISTS clips_sort_rank_index
                ON clips(is_deleted, sort_rank DESC);
                """,
            ]
        ),
        DatabaseMigration(
            version: 5,
            statements: [
                "ALTER TABLE clips ADD COLUMN is_retention_protected INTEGER NOT NULL DEFAULT 0;",
                """
                CREATE TABLE IF NOT EXISTS collections (
                    id TEXT NOT NULL PRIMARY KEY,
                    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
                    color_hex TEXT NOT NULL,
                    sort_order INTEGER NOT NULL,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL
                );
                """,
                """
                CREATE TABLE IF NOT EXISTS clip_collections (
                    clip_id TEXT NOT NULL,
                    collection_id TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    PRIMARY KEY (clip_id, collection_id),
                    FOREIGN KEY (clip_id) REFERENCES clips(id) ON DELETE CASCADE,
                    FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
                );
                """,
                """
                CREATE INDEX IF NOT EXISTS clip_collections_collection_index
                ON clip_collections(collection_id, created_at DESC);
                """,
                """
                CREATE INDEX IF NOT EXISTS clip_collections_clip_index
                ON clip_collections(clip_id);
                """,
                """
                INSERT OR IGNORE INTO collections (
                    id, name, color_hex, sort_order, created_at, updated_at
                ) VALUES
                    ('A1E4DA7D-EAFB-4E1F-A7B3-E5D83A11A101',
                     'Useful Links', '#FF453A', 10, 0, 0),
                    ('A1E4DA7D-EAFB-4E1F-A7B3-E5D83A11A102',
                     'Important Notes', '#FFB000', 20, 0, 0),
                    ('A1E4DA7D-EAFB-4E1F-A7B3-E5D83A11A103',
                     'Email Templates', '#30D158', 30, 0, 0),
                    ('A1E4DA7D-EAFB-4E1F-A7B3-E5D83A11A104',
                     'Code Snippets', '#0A84FF', 40, 0, 0);
                """,
            ]
        ),
    ]
}
