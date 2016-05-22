class Field:
	def __init__(self, width, height):
		self.width = width
		self.height = height

		self.bot = 0
		self.top = 19
		self.left = 0
		self.right = 9

		self.field = []
		self.set_field()

	def set_field(self):
		for i in range(self.height):
			self.field.append([0] * self.width)

	def pos_to_add_figure(self, figure):
		for i in range(4):
			for j in range(4):
				if figure.description[j][i] == 0:
					continue
				cur_cell = sum_two_2tuples(figure.pos, (i,-j))
				print(cur_cell)
				if not self.cell_in_field(cur_cell):
					return False
				if not self.is_empty_cell(cur_cell):
					return False
		return True

	def is_empty_cell(self, pos):
		return self.field[pos[1]][pos[0]] == 0

	def cell_in_field(self, pos):
		return self.left <= pos[0] <= self.right and self.bot <= pos[1] <= self.top


def sum_two_2tuples(tuple_a, tuple_b):
	return (tuple_a[0] + tuple_b[0], tuple_a[1] + tuple_b[1])