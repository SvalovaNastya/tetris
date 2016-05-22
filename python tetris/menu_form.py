#!/usr/bin/python3

from tkinter import *
import os
import sys
import game_form

class MenuForm:
	def __init__(self, root):
		self.root = root
		self.form_width = 100
		self.form_height = 200
		self.root.geometry(str(self.form_width) + 'x' + str(self.form_height))
		self.canvas = Canvas(self.root,
							 width=self.form_width,
							 height=self.form_height)
		self.canvas.place(x=0, y=0)
		self.set_widgets()

	def set_widgets(self):
		self.start_game_button = Button(self.root, text='Start game', command=self.start_game_function, height=1, width=10)
		self.start_game_button.place(x=25, y=50)

		self.quit_button = Button(self.root, text='Quit', command=self.quit_function, height=1, width=10)
		self.quit_button.place(x=25, y=100)

	def start_game_function(self):
		self.root.destroy()
		game_form.start()

	def quit_function(self):
		self.root.destroy()
		

def start():
	root = Tk()
	MenuForm(root)
	root.mainloop()


if __name__ == "__main__":
	start()