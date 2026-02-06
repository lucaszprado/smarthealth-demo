This README documents what is objective and the scaffold with the appropriate headers and placeholders for each file from the memory bank stucture.
When updating the files, follow these instructions keeping the appropriate headers and placeholders (if any) to ensure the files are updated correctly.

# project_brief.md
- Describe the overall project goals.

## Problem
- What is the problem the project aiming to to solve and why we want to solve it?

## Objectives
- What result we want to see in the end of the project?

## Organization
Some project have very clear boundaries since the begining.
When it's case we use this section to explain give an overview of projec phases.
In general phases are a feature, a user story, a subsystem.
On this Heading we list the project phases:

- Phase 1
- Phase 2
- Phase N

## Phase N: Phase name
Each phase is described at a high level on this section

### Objective
Which are the phase objetives?

### Key elements
- What are the desired user flows or key solution outputs?

### Out of Scope and No Gos
- Situations, edge cases, or any technical implementation we're chosing not to build in the current scope


# scope_context.md
- A project is composed by one or more scopes.
- Scopes are integrated "slices" of work. Think of it like phases with very integrated pieces of work. They reflect meaningful parts of the problem that can be completed **independently** or with very little dependence on other project scopes. Ideally they integrate frontend and backend.
- Each scope delivers a clear and testable increment, they easy code review process by avoiding context switching and keeping code changes under a trackable amount of files (less than 10 files ideally).
- This section explains in more detail the scope under development on the project right now.


## Scope objective
- What is the scope under development on the project right now?
- This is the actual piece or "slice" of work being built

## Key elements
- What are the key solution elements that define the current scope?
- What are the must have for the solution given scope?

## Out of scope and No-Gos
- Situations, edge cases, or any technical implementation we're chosing not to build in the current scope

# system_pattern.md
- This section documents what are the overall **design patterns in the project**
- What is the project architecture? What the architectural choices that build the logic required in the project?

# tech_constraints.md
- This section documents **stack choices in the project**
- What tecnical solutions we must use to meet the project and scope objectives?

# active_context.md
- A scope is composed by value delivery tasks - VDT.
- VDT are required pieces of work to complete a given scope.
- This section documents what are the needed VDT needed to complete a given scope and any relevant detail to be considered to build the VDTs

## VDTs
- Use the format below to document completed and pending value delivery tasks <br> <br>
[ ] Value Delivery task to be done <br>
[x] Value Delivery task Done

## Important notes regarding the building phase or implementation of this scope

### Issue N

# progress.md
- Document what are the required scopes to complete the overall project and not only the current scope specified in the scope objective section.
- This section is documented at scope level and not the value delivery task level
- Follow the placeholders below to document the overall progress
- This section is updated as we move forward in the project. We might split a given scope into new scopes, discard a given scope etc.
- If project has more than one phase, we group scopes under each phase


## Phase N
### Completed
- Scope 1
- Scope 2

### Under Development

### To be done
- Scope 3
- Scope 4
