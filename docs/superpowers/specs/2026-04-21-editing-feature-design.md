# SakunaFlow Editing Feature Design

Date: 2026-04-21
Status: Approved design, pending implementation plan

## Goal

Add full editing support for tasks and projects in SakunaFlow. The first version should make the existing local-first task and project data editable without introducing cloud sync behavior, new detail pages, or broad navigation changes.

## Scope

In scope:

- Edit task fields already present in the Drift schema:
  - title
  - description
  - project
  - priority
  - due date
  - estimated pomodoros
  - tags
- Edit project fields already present in the Drift schema:
  - name
  - description
  - color
  - status
  - tech tags
  - Git URL
- Open editing from the Today screen, Projects list, and Project detail task lists.
- Use autosave rather than an explicit Save button.
- Show save state in the edit panel.
- Preserve existing checkbox task completion behavior.

Out of scope:

- Editing calendar events, pomodoro session history, or settings.
- Cloud sync conflict handling.
- New task detail routes such as `/tasks/:id`.
- Rich text or markdown editing.
- Bulk editing.

## User Experience

Editing uses a shared panel pattern:

- On desktop and wide layouts, the editor appears as a right-side drawer.
- On narrow layouts, the same editor content appears as a bottom sheet.
- The list or detail page remains visible behind the editor so the user keeps context.
- Closing the panel does not discard confirmed autosaved changes.

Task rows and project cards should expose an edit affordance. The simplest first version is to open the panel when the main row/card area is clicked, while keeping existing checkbox and navigation actions working independently. If a row already has a primary navigation action, the implementation should prefer a small edit icon or overflow menu to avoid surprising navigation changes.

## Autosave Behavior

Autosave is required.

- Text fields save after a short idle delay, approximately 500 ms after the latest edit.
- Selectors, date pickers, color pickers, numeric steppers, and chip changes save immediately after the user chooses a value.
- The panel displays one of these states:
  - `儲存中`
  - `已儲存`
  - `儲存失敗`
- Failed saves keep the user's current input visible and keep the panel open.
- Failed saves show a concise error message near the save state.
- Empty optional text fields are stored as `null`, matching existing `_blankToNull` behavior.
- Required text fields are not saved while empty. The field should show validation feedback until it has a non-empty value.

## Architecture

Add a reusable edit surface and two feature-specific editors:

- `EditPanelScaffold`
  - Owns desktop drawer vs narrow bottom-sheet presentation.
  - Provides title, close action, save-state area, and scrollable body.
  - Does not know task or project field semantics.
- `TaskEditPanel`
  - Renders task fields.
  - Owns task field controllers and debounced text saves.
  - Calls database task update APIs.
- `ProjectEditPanel`
  - Renders project fields.
  - Owns project field controllers and debounced text saves.
  - Calls database project update APIs.

Screens should keep only the selected edit target in local widget state:

- Today screen can select a task for editing.
- Projects screen can select a project from the list or detail header.
- Project detail task lists can select a task for editing.

The edit panel should receive the latest streamed `Task` or `Project` object when available, so external changes update the form without needing a full screen refresh. While a field is actively being edited, the controller should not be overwritten by an incoming stream update unless the editor is reset or closed.

## Data Layer

Add focused update methods to `AppDatabase`:

- `updateTask(...)`
  - Accepts editable task fields as optional parameters.
  - Trims string values.
  - Converts blank optional strings to `null`.
  - Updates `updatedAt`.
  - Does not modify `completedAt` or status unless a future caller explicitly needs status editing.
- `updateProject(...)`
  - Accepts editable project fields as optional parameters.
  - Trims string values.
  - Converts blank optional strings to `null`.
  - Updates `updatedAt`.

The UI should not create Drift companions directly. Drift write details stay in the database layer.

## Validation

Task validation:

- Title is required and must remain within the existing database length limit.
- Description is optional and follows the existing database length limit.
- Estimated pomodoros cannot be negative.
- Priority must remain in the existing app range: `0` = P0, `1` = P1, `2` = P2, `3` = P3.
- Project may be cleared to represent no project.
- Tags are stored as a list of trimmed, non-empty strings.

Project validation:

- Name is required and must remain within the existing database length limit.
- Description is optional and follows the existing database length limit.
- Color must be one of the first-version project palette values: `#8c52ff`, `#0075de`, `#2a9d99`, `#dd5b00`, `#d93838`, `#2f7d4f`, `#888888`.
- Status must be one of the existing `ProjectStatus` values.
- Tech tags are stored as a list of trimmed, non-empty strings.
- Git URL is optional. The first version may validate only that the value is non-empty after trimming before storing it; stricter URL validation can be added later.

## Error Handling

Errors should be local to the panel:

- Validation errors appear next to the relevant field.
- Database write errors update the save state to `儲存失敗`.
- A failed autosave should not close the panel or revert the user's visible input.
- Retrying happens naturally when the user edits again. A manual retry button can be added if implementation cost is low, but it is not required for the first version.

## Testing

Database tests:

- `updateTask` updates all editable fields and `updatedAt`.
- `updateTask` converts blank optional strings to `null`.
- `updateProject` updates all editable fields and `updatedAt`.
- `updateProject` converts blank optional strings to `null`.
- Invalid required values are rejected before writing or fail predictably in the database layer.

Widget tests:

- Tapping a task edit affordance opens the task edit panel.
- Editing a task text field triggers autosave after the debounce.
- Choosing a project, priority, due date, estimated pomodoros, or tag value updates the task.
- Tapping a project edit affordance opens the project edit panel.
- Editing a project field updates the visible project list or detail header after the stream emits.
- Save-state text transitions through saving and saved for successful writes.
- Failed writes show `儲存失敗` and keep the panel open.

## Acceptance Criteria

- A user can edit full task fields from Today and Project detail task lists.
- A user can edit full project fields from the Projects list and Project detail header.
- Edits persist in Drift and are reflected in existing streams.
- Autosave works for text and non-text fields.
- Required fields cannot be saved empty.
- The edit surface behaves as a right drawer on wide layouts and a bottom sheet on narrow layouts.
- Existing task completion toggles continue to work.
- Existing project navigation continues to work.
