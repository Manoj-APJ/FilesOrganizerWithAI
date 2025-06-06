/*
  # Initial Schema Setup for AI Lecture Notes

  1. New Tables
    - `users`
      - `id` (uuid, primary key) - Maps to Supabase Auth user ID
      - `email` (text) - User's email address
      - `created_at` (timestamp) - Account creation timestamp
    
    - `notes`
      - `id` (uuid, primary key) - Unique note identifier
      - `user_id` (uuid) - References users.id
      - `title` (text) - Note title
      - `content` (text) - Note content or extracted text
      - `file_url` (text) - URL to stored file
      - `file_type` (text) - Type of file (pdf, image, text, markdown)
      - `category` (text) - Note category
      - `summary` (text) - AI-generated summary
      - `created_at` (timestamp) - Creation timestamp
      - `updated_at` (timestamp) - Last update timestamp

    - `note_tags`
      - `id` (uuid, primary key) - Unique tag identifier
      - `note_id` (uuid) - References notes.id
      - `tag` (text) - Tag name
      - `created_at` (timestamp) - Tag creation timestamp

    - `annotations`
      - `id` (uuid, primary key) - Unique annotation identifier
      - `note_id` (uuid) - References notes.id
      - `text` (text) - Highlighted text
      - `content` (text) - Annotation content
      - `color` (text) - Highlight color
      - `position` (jsonb) - Position data {x, y, pageNumber}
      - `created_at` (timestamp) - Creation timestamp

  2. Security
    - Enable RLS on all tables
    - Add policies for user-specific data access
*/

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  email text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS for users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) NOT NULL,
  title text NOT NULL,
  content text,
  file_url text,
  file_type text NOT NULL,
  category text,
  summary text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS for notes
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create note_tags table
CREATE TABLE IF NOT EXISTS note_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id uuid REFERENCES notes(id) ON DELETE CASCADE NOT NULL,
  tag text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS for note_tags
ALTER TABLE note_tags ENABLE ROW LEVEL SECURITY;

-- Create annotations table
CREATE TABLE IF NOT EXISTS annotations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id uuid REFERENCES notes(id) ON DELETE CASCADE NOT NULL,
  text text NOT NULL,
  content text NOT NULL,
  color text NOT NULL,
  position jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS for annotations
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Users policies
CREATE POLICY "Users can read own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Notes policies
CREATE POLICY "Users can CRUD own notes"
  ON notes
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Note tags policies
CREATE POLICY "Users can CRUD tags for own notes"
  ON note_tags
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM notes
    WHERE notes.id = note_tags.note_id
    AND notes.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM notes
    WHERE notes.id = note_tags.note_id
    AND notes.user_id = auth.uid()
  ));

-- Annotations policies
CREATE POLICY "Users can CRUD annotations for own notes"
  ON annotations
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM notes
    WHERE notes.id = annotations.note_id
    AND notes.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM notes
    WHERE notes.id = annotations.note_id
    AND notes.user_id = auth.uid()
  ));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS notes_user_id_idx ON notes(user_id);
CREATE INDEX IF NOT EXISTS note_tags_note_id_idx ON note_tags(note_id);
CREATE INDEX IF NOT EXISTS annotations_note_id_idx ON annotations(note_id);