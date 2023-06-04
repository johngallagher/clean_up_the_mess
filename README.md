# Clean Up The Mess - Example App

Structure of this exercise

Act 1

* Sets up the story
* Introduce characters
* Create relationships
* Establish hero's unfulfilled desire

Act 2

* Dramatic action
* Held together by confrontation
* Hero encounters obstacles which prevent them achieving their desire

Act 3

* Resolves the story
* Solution - did the character succeed or fail?


# Act 1

What do we want?

Protect our app from hackers.

What have we got?

* Rails app
* Creating microposts
* Calls out to Castle
* Detects hackers and presents them with 500 errors
* Code is messy

# Act 2

* A series of changes
* We'll see how the design responds to these changes

## Change 1: Use policies instead of risk levels

## Change 2: Block IP using Cloudflare

## Change 3: Add challenges using Cloudflare

### Act 2A - The Normal Way

* "Hack in" each of these changes in the simplest way possible.
* Very little abstraction.
* Typical code I see in projects
* "Shovel the shit" around

### Act 2B - The Designed Way

* Use objects to abstract behaviour away
* Assess coupling and concern metrics using techniques
* Tidy first, then change behaviour

## Act 2C - Comparison

* Use a diagram to compare the normal way with the designed way.
* Examine tradeoffs
* Compare and contrast the two approaches
* Sliding scale

# Act 3 - Conclusion

* I've introduced the principles to you
* Recap the techniques and principles
* The really hard part - judgement - is another book.
* Go forth and look for interfaces.
