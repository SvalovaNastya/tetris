class Figure:
	def __init__(self, figure_description, figure_name):
		self.pos = (0, 0)
		self.description = figure_description
		self.name = figure_name

	def set_pos(self, new_pos):
		pos = new_pos

class FigureGenerator:
	def __init__(self):
		self.pos_descriprions = self.get_possible_descriprions()
		self.possible_names = self.get_possible_names()
		self.cur_random_number = 19

	def get_possible_names(self):
		return ['1', '2', '3', '4', '5', '6', '7']

	def get_possible_descriprions(self):
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

	def get_next_figure(self):
		next_figure = random.randrange(len(self.descriptions))
		return Figure((4, 20), self.descriptions[next_figure], self.possible_names[next_figure])