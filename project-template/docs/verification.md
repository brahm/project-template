# Verification

What the work of {{PROJECT_NAME}} is checked against, where, and how the
result is recorded. "It looks right" is not a check.

## The references

| Reference | Used for | Where it runs |
| --- | --- | --- |
| e.g. the specification, version X | Everything it defines | CI |
| e.g. the product being matched, version Y | Behaviour and layout | The owner's machine, by screen control |
| e.g. an older version, kept for what only it has | Features only it has | A virtual machine set up for this |

When two references disagree, the decisions say which one wins.

## Reference cases

A reference case is an input made with, or taken from, the reference, plus
the output the reference gives. Name each case after the inventory row it
checks, so that a failing test points to the row. Keep cases made by the
project; never commit material whose licence forbids it.

## Parity documents

When an item is checked by comparing with a reference by eye (screenshots,
documents side by side), the comparison is a document of its own: what was
compared, on which version and machine, on which day, what matched, what
did not, and the row it belongs to. It is kept with the reference cases or
linked from the inventory row.

## Recording the result

The inventory row says how the item was checked (`note`) and its status.
An item is done only when it was checked against its reference and nothing
asks for a second look (`review` is `-`).
