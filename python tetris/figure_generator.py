import random

class Figure:
	def __init__(self, figure_position, figure_description, figure_name, figure_color):
		self.pos = figure_position
		self.description = figure_description
		self.name = figure_name
		self.color = figure_color

	def print(self):
		print("Current figure:")
		print(self.pos)
		print(self.description)
		print(self.color)
		print(self.name)

	def set_pos(self, new_pos):
		pos = new_pos

class FigureGenerator:
	def __init__(self):
		self.pos_descriptions = self.get_possible_descriptions()
		self.possible_names = self.get_possible_names()
		self.possible_colors = self.get_possible_colors()
		self.cur_random_number = 19

	def get_possible_colors(self):
		return ['red', 'yellow', 'green', 'blue', 'black', 'orange']

	def get_possible_names(self):
		return ['1', '2', '3', '4', '5', '6', '7']

	def get_possible_descriptions(self):
		descriptions = []
		descriptions.append([[0, 0, 0, 0],
							 [0, 1, 1, 0],
							 [1, 1, 0, 0],
							 [0, 0, 0, 0]])

		descriptions.append([[0, 0, 0, 0],
							 [1, 1, 1, 1],
							 [0, 0, 0, 0],
							 [0, 0, 0, 0]])
		
		descriptions.append([[0, 0, 0, 0],
							 [0, 1, 1, 0],
							 [0, 0, 1, 1],
							 [0, 0, 0, 0]])
		
		descriptions.append([[0, 0, 0, 0],
							 [1, 1, 1, 0],
							 [0, 0, 1, 0],
							 [0, 0, 0, 0]])
		
		descriptions.append([[0, 0, 0, 0],
							 [0, 1, 1, 1],
							 [0, 1, 0, 0],
							 [0, 0, 0, 0]])
		
		descriptions.append([[0, 0, 0, 0],
							 [0, 1, 1, 0],
							 [0, 1, 1, 0],
							 [0, 0, 0, 0]])

		descriptions.append([[0, 0, 0, 0],
							 [0, 1, 0, 0],
							 [1, 1, 1, 0],
							 [0, 0, 0, 0]])
		return descriptions

	def get_next_figure(self):
		cur_color = random.randrange(len(self.possible_colors))
		next_figure = random.randrange(len(self.pos_descriptions))
		return Figure((4, 20), self.pos_descriptions[next_figure], self.possible_names[next_figure], self.possible_colors[cur_color])