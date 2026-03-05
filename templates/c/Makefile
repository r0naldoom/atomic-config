CC = gcc
CFLAGS = -Wall -Wextra -g
TARGET = main

$(TARGET): main.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)

.PHONY: clean
