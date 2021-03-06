#!/usr/bin/python3

from tkinter import *
import os
import sys
import menu_form
from field import Field
from time import time
from figure_generator import FigureGenerator

class GameForm:
	def __init__(self, root):
		self.root = root
		self.form_width = 360
		self.form_height = 500
		self.cell_size = 24
		self.root.geometry(str(self.form_width) + 'x' + str(self.form_height))
		self.canvas = Canvas(self.root,
							 width=self.form_width, 
							 height=self.form_height)
		self.canvas.place(x=0, y=0)
		self.set_widgets()
		self.draw_grid()

		self.paused = False
		self.game_end = False

		self.field = Field(10, 20)
		self.time_to_move_down = time() + 1000

		self.root.bind("<Key>", self.key_pressed)
		self.drawed_cur_figure = None

		self.cur_figure = None
		self.figure_generator = FigureGenerator()
		self.next_figure = self.figure_generator.get_next_figure()


	def key_pressed(self, event):
		key = event.keysym
		if key == 'Left':
			self.try_move_figure((0, -1))
		if key == 'Right':
			self.try_move_figure((0, 1))
		if key == 'Down':
			self.try_move_figure((1, 0))
		if key == 'space':
			self.change_pause_state()

	def change_pause_state(self):
		if self.paused:
			self.paused = False
			self.canvas.delete(self.drawed_pause_state)
		else:
			self.paused = True
			self.drawed_pause_state = self.canvas.create_text(305, 150, text='PAUSED')

	def start_new_turn(self):
		self.cur_figure = self.next_figure
		self.next_figure = self.figure_generator.get_next_figure()

		self.cur_figure.print()

		if not self.field.pos_to_add_figure(self.cur_figure):
			self.game_end = True
			return
		self.redraw_cur_figure()

	def redraw_cur_figure(self):
		if not self.drawed_cur_figure == None:
			for drawed_cell in self.drawed_cur_figure:
				self.canvas.delete(drawed_cell)
		drawed_parts = []
		self.cur_figure.print()
		for i in range(4):
			for j in range(4):
				if self.cur_figure.description[i][j] == 0:
					continue
				drawed_parts.append(self.draw_cell(sum_two_2tuples(self.cur_figure.pos, (j, -i)), self.cur_figure.color))


	def draw_cell(self, pos, color):
		r_pos = (pos[0], 19 - pos[1])
		return self.canvas.create_polygon(10 + self.cell_size * r_pos[0], 10 + self.cell_size * r_pos[1],
										  10 + self.cell_size * (r_pos[0] + 1), 10 + self.cell_size * r_pos[1],
										  10 + self.cell_size * (r_pos[0] + 1), 10 + self.cell_size * (1 + r_pos[1]),
										  10 + self.cell_size * r_pos[0], 10 + self.cell_size * (1 + r_pos[1]),
										  fill=color)

	def game(self):
		if self.game_end:
			return
		if self.cur_figure == None:
			self.start_new_turn()
		# print(self.game_end)
		if not self.game_end and not self.paused and time() > self.time_to_move_down:
			pass
		self.root.after(1, self.game)

	def set_widgets(self):
		# self.draw_button = Button(self.root, text='Draw', command=self.draw_button_function, height=1, width=10)
		# self.draw_button.place(x=80, y=400)

		self.back_button = Button(self.root, text='Main Menu', command=self.back_to_main_menu_function, height=1, width=10)
		self.back_button.place(x=265, y=450)

	def back_to_main_menu_function(self):
		self.root.destroy()
		menu_form.start()

	def draw_grid(self):
		self.draw_borders()

		#vertical lines
		for i in range(9):
			cur_x_coor = 10 + self.cell_size * (i + 1)
			self.canvas.create_line(cur_x_coor, 10,
									cur_x_coor, 490,
									fill='grey', width=1)

		#horizontal lines
		for i in range(19):
			cur_y_coor = 10 + self.cell_size * (i + 1)
			self.canvas.create_line(10, cur_y_coor,
									250, cur_y_coor,
									fill='grey', width=1)


	def draw_borders(self):
		# self.canvas.create_line(260, 10, 260, 490, fill='grey', width=2)
		self.canvas.create_line(10, 10, 250, 10, fill='grey', width=2)
		self.canvas.create_line(250, 10, 250, 490, fill='grey', width=2)
		self.canvas.create_line(250, 490, 10, 490, fill='grey', width=2)
		self.canvas.create_line(10, 10, 10, 490, fill='grey', width=2)


def sum_two_2tuples(tuple_a, tuple_b):
	return (tuple_a[0] + tuple_b[0], tuple_a[1] + tuple_b[1])


def start():
	root = Tk()
	game = GameForm(root)
	game.game()
	root.mainloop()


if __name__ == "__main__":
	start()