#include <stdio.h>
#include <iostream>
#include <string.h>
#include <map>
#include <cmath>
#include <vector>

/* link data and function with bison and flex */
#include "datalink.h"

#include <GL/glut.h>

#define   PI   3.14159265358979

std::string SceneInfo(""), Title("Unnamed"), ViewerInfo("");
float BackgroundColor[4] = { 0, 0, 0, 1 };
/* window shape */
int width = 500, height = 500;

bool is_Perspective = true;

GLUquadricObj  *sphere = NULL;

float dir = 10;

/* eye pos */
float  pos[3] = { 0.0, 0.0, 0.0 };

/* focus pos */
float  focus[3] = { 0.0, 0.0, 0.0 };

/* view up */
float  view_up[3] = { 0.0, 0.0, 0.0 };

/* eye pos (polar coordinate system) */
float  polar_pos[3] = { 30.0, 30.0, 1.0 };

float light_amb[4] = { 0.3, 0.3, 0.3, 1.0 };
float light_spe[4] = { 0.9, 0.9, 0.9, 1.0 };
float light_temp[4] = { 0.0, 0.0, 0.0, 0.0 };
//declare the rotational angle.
float  angle = 0.0;
double* uniform(double vecIn[], double vecOut[])
{
		double avg=0;
		for(int i=2;i>=0;i--){
				avg+=vecIn[i]*vecIn[i];
		}
		avg=sqrt(avg);
		//cout<< "length:"<<avg<<endl;
		for(int i=2;i>=0;i--){
				vecOut[i]=vecIn[i]/avg;
		}
		return vecOut;
}
void update_eye_pos(){
	if(dir <= 0.5)dir = 0.5;
	if( polar_pos[0] <= 0 ) polar_pos[0] += 360;
	if( polar_pos[0] > 360 ) polar_pos[0] -= 360;
	if( polar_pos[1] <= 0 ) polar_pos[1] += 360;
	if( polar_pos[1] > 360 ) polar_pos[1] -= 360;
	if( fabs(polar_pos[2] - 1.0) >= 0.01 )polar_pos[2] = 1.0;

	float theta = polar_pos[0] * PI / 180;
	float psi = polar_pos[1] * PI / 180;
	float sgn_ph = polar_pos[2];

	if ((psi >= PI / 4))sgn_ph = -1;
	if ((psi >= PI * 1.25))sgn_ph = 1;

	pos[0] = focus[0] + dir * cos(theta) * cos(psi);
	pos[1] = focus[1] + dir * sin(psi);
	pos[2] = focus[2] + dir * sin(theta) * cos(psi);

	view_up[0] = cos(theta) * sgn_ph;
	view_up[1] = sgn_ph;
	view_up[2] = sin(theta) * sgn_ph;

	glutPostRedisplay();
}

inline void draw_lines(std::vector< std::vector<double> > point_list, std::vector< indexed_line_t > * line_array){
		int max_LineSetData = line_array->size();
		int max_point = point_list.size();
		if(max_LineSetData){
				glBegin(GL_LINES);
				for(int i = 0; i<max_LineSetData; i++){
						indexed_line_t line_buffer = line_array->at(i);
						if(	line_buffer.start >= max_point || line_buffer.start < 0 ||
								line_buffer.end >= max_point || line_buffer.end < 0) continue;
						glVertex3f(point_list[line_buffer.start][0], point_list[line_buffer.start][1], point_list[line_buffer.start][2]);
						glVertex3f(point_list[line_buffer.end][0], point_list[line_buffer.end][1], point_list[line_buffer.end][2]);
				}
				glEnd();
		}
}

inline void draw_faces(std::vector< std::vector<double> > point_list, face_item_t face_item){
		int max_LineSetData = face_item.point_indexs.size();
		int max_point = point_list.size();
		if(max_LineSetData){
				for(int i = 0; i<max_LineSetData; i++){
						int face_index = face_item.point_indexs[i];
						if(face_index >= max_point || face_index < 0) return;
				}
				glBegin(GL_POLYGON);
						for(int i = 0; i<max_LineSetData; i++){
								int face_index = face_item.point_indexs[i];
								glVertex3f(point_list[face_index][0], point_list[face_index][1], point_list[face_index][2]);
						}
				glEnd();
		}
}

void calc_cross(std::vector< std::vector<double> > point_list, face_item_t& face_item){
		double result[3], norm[3];
		int face_vertex = face_item.point_indexs.size();
		if(face_vertex < 3){
				std::cout << "Face Degeneracy.";
				return;
		}

		double vec1[3] = {point_list[face_item.point_indexs[0]][0] - point_list[face_item.point_indexs[1]][0],
											point_list[face_item.point_indexs[0]][1] - point_list[face_item.point_indexs[1]][1],
											point_list[face_item.point_indexs[0]][2] - point_list[face_item.point_indexs[1]][2]};
		double vec2[3] = {point_list[face_item.point_indexs[2]][0] - point_list[face_item.point_indexs[1]][0],
											point_list[face_item.point_indexs[2]][1] - point_list[face_item.point_indexs[1]][1],
											point_list[face_item.point_indexs[2]][2] - point_list[face_item.point_indexs[1]][2]};
		cross(vec1, vec2, result);
		uniform(result, norm);
		fill_vec3_from_vec4(face_item.normal, norm);

		std::cout << "< " << vec1[0] << ", " << vec1[1] << ", " << vec1[2] << " > x < ";
		std::cout					<< vec2[0] << ", " << vec2[1] << ", " << vec2[2] << " > = < ";
		std::cout					<< face_item.normal[0] << ", " << face_item.normal[1] << ", " << face_item.normal[2] << " > " << std::endl;
		//double vec1[3]
}
double* cross(double vec1[], double vec2[], double vec3[])
{
		vec3[0] = vec1[1] * vec2[2] - vec2[1] * vec1[2];
		vec3[1] = -vec1[0] * vec2[2] + vec2[0] * vec1[2];
		vec3[2] = vec1[0] * vec2[1] - vec2[0] * vec1[1];
		return vec3;
}
inline void print_string(std::string str, int x, int y){
		int pos_x = x;
		int pos_y = y;
		if(pos_x<=0||pos_y<=0){ pos_x = 0;  pos_y = 0;}
		glPushMatrix();
				glDisable(GL_LIGHTING);
				GLint old_matrix = GL_ZERO;
				glGetIntegerv(GL_MATRIX_MODE, &old_matrix);
				glMatrixMode(GL_PROJECTION);
				glPushMatrix();
						glLoadIdentity();
						gluOrtho2D(0.0, width, 0.0, height);
						glMatrixMode(GL_MODELVIEW);
		 				glPushMatrix();
				 				glLoadIdentity();
								glRasterPos2i(pos_x, height - pos_y);
								for ( std::string::iterator it=str.begin(); it!=str.end(); ++it){
									 char key = *it;
									 if(key == '\n'){
										 pos_y += 20;
										 pos_x = x;
										 glRasterPos2i(pos_x, height - pos_y);
										 continue;
									 }
									 glutBitmapCharacter(GLUT_BITMAP_8_BY_13, (int) key);
									 //pos_x += 10;
								}
								glMatrixMode(GL_MODELVIEW);
						glPopMatrix();
						glMatrixMode(GL_PROJECTION);
				glPopMatrix();
				glMatrixMode(old_matrix);
		glPopMatrix();
}

inline float* vec4dv2vec4fv(const double vecdv[4]){
		light_temp[0] = (float)vecdv[0];
		light_temp[1] = (float)vecdv[1];
		light_temp[2] = (float)vecdv[2];
		light_temp[3] = (float)vecdv[3];
		return light_temp;
}

void printvec4fv(const float vecdv[4]){
		std::cout << "( "<< vecdv[0] << ", ";
		std::cout << vecdv[1] << ", ";
		std::cout << vecdv[2] << ", ";
		std::cout << vecdv[3] << " )" << std::endl;
}

inline void set_material(Material_data_t * meterial){
		glMaterialfv(GL_FRONT, GL_AMBIENT, vec4dv2vec4fv(meterial->ambientColor));
		glMaterialfv(GL_BACK, GL_AMBIENT, vec4dv2vec4fv(meterial->ambientColor));

		glMaterialfv(GL_FRONT, GL_SPECULAR, vec4dv2vec4fv(meterial->specularColor));
		glMaterialfv(GL_BACK, GL_SPECULAR, vec4dv2vec4fv(meterial->specularColor));

		glMaterialfv(GL_FRONT, GL_DIFFUSE, vec4dv2vec4fv(meterial->diffuseColor));
		glMaterialfv(GL_BACK, GL_DIFFUSE, vec4dv2vec4fv(meterial->diffuseColor));

		glMaterialfv(GL_FRONT, GL_EMISSION, vec4dv2vec4fv(meterial->emissiveColor));
		glMaterialfv(GL_BACK, GL_EMISSION, vec4dv2vec4fv(meterial->emissiveColor));

		//glMaterialf(GL_FRONT, GL_SHININESS, meterial->shininess);
		//glMaterialf(GL_BACK, GL_SHININESS, meterial->shininess);
}
inline GLenum get_light_id(int light_id){
		switch(light_id){
				case 0:
						return GL_LIGHT0;
						break;
				case 1:
						return GL_LIGHT1;
						break;
				case 2:
						return GL_LIGHT2;
						break;
				case 3:
						return GL_LIGHT3;
						break;
				case 4:
						return GL_LIGHT4;
						break;
				case 5:
						return GL_LIGHT5;
						break;
				case 6:
						return GL_LIGHT6;
						break;
				case 7:
						return GL_LIGHT7;
						break;
				default:
						return GL_LIGHT0;
						break;
		}
}
inline void setting_light(){
		std::vector<light_struct> lightdata = get_light_lists();
		int max_light = lightdata.size();
		if(max_light > 8){
				max_light = 8;
				std::cout << "Open GL juse support 8 light!" << std::endl;
		}
		glEnable(GL_LIGHTING);
				for(int i=0; i<max_light; i++){
					glEnable(get_light_id(i));
							glLightfv(get_light_id(i), GL_AMBIENT, light_amb);
							glLightfv(get_light_id(i), GL_DIFFUSE, vec4dv2vec4fv(lightdata[i].color));
							glLightfv(get_light_id(i), GL_SPECULAR, light_spe);
							glLightfv(get_light_id(i), GL_POSITION, vec4dv2vec4fv(lightdata[i].position));
					glDisable(get_light_id(i));
				}
		glDisable(GL_LIGHTING);
}
inline void on_off_light(bool on_off){
		std::vector<light_struct> lightdata = get_light_lists();
		int max_light = lightdata.size();
		if(max_light > 8)max_light = 8;
		if(on_off) {for (int i=0; i<max_light; i++) glEnable(get_light_id(i)); glEnable(GL_LIGHTING);}
		else {for (int i=0; i<max_light; i++) glDisable(get_light_id(i)); glDisable(GL_LIGHTING);}
}
float* fillvec4f(float x, float y, float z, float w){
	light_temp[0] = x; light_temp[1] = y; light_temp[2] = z; light_temp[3] = w;
	return light_temp;
}

void ColorInit(float r, float g, float b)
{
	glColor3f(r, g, b); //set polygon material
	glMaterialfv(GL_FRONT, GL_AMBIENT, fillvec4f(r * 0.3, g * 0.3, b * 0.3, 1.0));
	glMaterialfv(GL_FRONT, GL_DIFFUSE, fillvec4f(r * 0.9, g * 0.9, b * 0.9, 1.0));
	glMaterialfv(GL_FRONT, GL_SPECULAR, fillvec4f(r * 0.8, g * 0.8, b * 0.8, 1.0));
}

inline void fix_light_pos(){
		std::vector<light_struct> lightdata = get_light_lists();

		glLightfv(GL_LIGHT0, GL_POSITION, vec4dv2vec4fv(lightdata[0].position));
}
inline void draw_all_faces(std::vector< std::vector<double> > point_list, std::vector<face_item_t> * face_list){
		on_off_light(true);
		glPushMatrix();
		int max_face_vertex = face_list->size();
		for(int i=0; i<max_face_vertex; i++){
				glNormal3f(face_list->at(i).normal[0],face_list->at(i).normal[1],face_list->at(i).normal[2]);
				int max_LineSetData = face_list->at(i).point_indexs.size();
				int max_point = point_list.size();
				if(max_LineSetData){
						bool skip_face = false;
						double midlept[3] = {0.0, 0.0, 0.0};
						for(int j = 0; j<max_LineSetData; j++){
								int face_index = face_list->at(i).point_indexs[j];
								if(face_index >= max_point || face_index < 0) {
										skip_face = true;
										break;
								}
								midlept[0] += point_list[face_index][0];
								midlept[1] += point_list[face_index][1];
								midlept[2] += point_list[face_index][2];
						}
						midlept[0] /= max_LineSetData;
						midlept[1] /= max_LineSetData;
						midlept[2] /= max_LineSetData;
						if(skip_face) continue;
						if(face_list->at(i).is_convex){
								glBegin(GL_POLYGON);
										for(int j = 0; j<max_LineSetData; j++){
												int face_index = face_list->at(i).point_indexs[j];
												glVertex3f(point_list[face_index][0], point_list[face_index][1], point_list[face_index][2]);
										}
								glEnd();
						}else{
								glDisable(GL_CULL_FACE);
								//使用Stencil buffer實現奇數次保留，偶數次消滅
								glEnable(GL_STENCIL_TEST);
								glClear(GL_STENCIL_BUFFER_BIT);

								glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
								glStencilFunc(GL_ALWAYS, 0, 1);
								glStencilOp(GL_KEEP, GL_KEEP, GL_INVERT);
								glStencilMask(1);

								glBegin(GL_TRIANGLE_FAN);
										glMatrixMode(GL_MODELVIEW);
										glPushMatrix();
												glPushMatrix();
														glDisable(GL_LIGHTING);
														GLint old_matrix = GL_ZERO;
														glGetIntegerv(GL_MATRIX_MODE, &old_matrix);
														glMatrixMode(GL_PROJECTION);
														glPushMatrix();
																glLoadIdentity();
																gluOrtho2D(0.0, width, 0.0, height);
																glMatrixMode(GL_MODELVIEW);
																glPushMatrix();
																		glLoadIdentity();
																		glVertex2f(0.0f, 0.0f);
																		glMatrixMode(GL_MODELVIEW);
																glPopMatrix();
																glMatrixMode(GL_PROJECTION);
														glPopMatrix();
														glMatrixMode(old_matrix);
												glPopMatrix();
												glMatrixMode(GL_MODELVIEW);
										glPopMatrix();
										//glVertex3f(midlept[0],midlept[1],midlept[2]);
										int first_face_index = face_list->at(i).point_indexs[0];
										for(int j = 0; j<max_LineSetData; j++){
												int face_index = face_list->at(i).point_indexs[j];
												glVertex3f(point_list[face_index][0], point_list[face_index][1], point_list[face_index][2]);
										}
										glVertex3f(point_list[first_face_index][0], point_list[first_face_index][1], point_list[first_face_index][2]);
								glEnd();

								glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
								glStencilFunc(GL_EQUAL, 1, 1);
								glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
								//glStencilOp(GL_ZERO,  GL_ZERO, GL_ZERO);

								glBegin(GL_POLYGON);
										for(int j = 0; j<max_LineSetData; j++){
												int face_index = face_list->at(i).point_indexs[j];
												glVertex3f(point_list[face_index][0], point_list[face_index][1], point_list[face_index][2]);
										}
										//glVertex3f(point_list[first_face_index][0], point_list[first_face_index][1], point_list[first_face_index][2]);
								glEnd();
								glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
								glClearStencil(0);
								glDisable(GL_STENCIL_TEST);

								glEnable(GL_CULL_FACE);
						}
				}
		}
		on_off_light(false);
		glPopMatrix();
}

void  myinit()
{
	glClearColor(BackgroundColor[0], BackgroundColor[1], BackgroundColor[2], BackgroundColor[3]);      /*set the background color BLACK */
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); /*Clear the Depth & Color Buffers */

	glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);  /*Enable depth buffer for shading computing */
  glEnable(GL_NORMALIZE);   /*Enable mornalization  */

	glViewport(0, 0, width, height);
	/*-----Set a Perspective projection mode-----*/
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(90.0, (double) width/ (double) height, 1.5, 500.0);

	//glOrtho(-8.0, 8.0, -8.0, 8.0, 0.0, 20.0);

	glEnable(GL_DEPTH_TEST);  /*Enable depth buffer for shading computing */
	update_eye_pos();

	if (sphere == NULL) {
		sphere = gluNewQuadric();
		gluQuadricDrawStyle(sphere, GLU_FILL);
		gluQuadricNormals(sphere, GLU_SMOOTH);  /* Generate normals */
	}

	 glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE);
	/*-----Enable face culling -----*/
	glCullFace(GL_BACK);
	glEnable(GL_CULL_FACE);

	glFlush();/*Enforce window system display the results*/
}

void draw_floor(float y_axis)
{
	int   i, j;

	for (i = -10; i<10; i++)
		for (j = -10; j<10; j++) {
			if ((i + j) % 2 == 0) ColorInit(0.9, 0.9, 0.9);
			else ColorInit(0.2, 0.2, 0.2);
			glNormal3f(0.0, 1.0, 0.0);
			glBegin(GL_POLYGON);
				glVertex3f(i, y_axis, j);
				glVertex3f(i, y_axis, j + 1);
				glVertex3f(i + 1, y_axis, j + 1);
				glVertex3f(i + 1, y_axis, j);
			glEnd();
		}
}

void DrawAxis() {
	glLineWidth(1.0);
	glDisable(GL_LIGHTING);
	glBegin(GL_LINES);
		//x axis
		glColor3f(1, 0, 0);
		glVertex3f(0, 0, 0);
		glVertex3f(500, 0, 0);

		glVertex3f(500, 0, 0);
		glVertex3f(0, 0, 0);
		//-x axis
		glColor3f(0.5, 0, 0);
		glVertex3f(0, 0, 0);
		glVertex3f(-500, 0, 0);

		glVertex3f(-500, 0, 0);
		glVertex3f(0, 0, 0);
		//y axis
		glColor3f(0, 1, 0);
		glVertex3f(0, 0, 0);
		glVertex3f(0, 500, 0);

		glVertex3f(0, 500, 0);
		glVertex3f(0, 0, 0);
		//-y axis
		glColor3f(0, 0.5, 0);
		glVertex3f(0, 0, 0);
		glVertex3f(0, -500, 0);

		glVertex3f(0, -500, 0);
		glVertex3f(0, -0, 0);
		//z axis
		glColor3f(0, 0, 1);
		glVertex3f(0, 0, 0);
		glVertex3f(0, 0, 500);

		glVertex3f(0, 0, 500);
		glVertex3f(0, 0, 0);
		//-z axis
		glColor3f(0, 0, 0.5);
		glVertex3f(0, 0, 0);
		glVertex3f(0, 0, -500);

		glVertex3f(0, 0, -500);
		glVertex3f(0, 0, -0);
	glEnd();
}

void display()
{
	glClearColor(BackgroundColor[0], BackgroundColor[1], BackgroundColor[2], BackgroundColor[3]);
	/*Clear previous frame and the depth buffer */
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	ColorInit(0.6, 0.6, 0.6);
	print_string(SceneInfo,5,height - 25);

	ColorInit(0.9, 0.9, 0.9);
	print_string(Title,5,15);
	/*----Define the current eye position and the eye-coordinate system---*/
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	gluLookAt(pos[0], pos[1], pos[2], focus[0], focus[1], focus[2], view_up[0], view_up[1], view_up[2]);

	//std::cout << pos[0] << ", " << pos[1] << ", " << pos[2] << std::endl;
	fix_light_pos();
	/*-------Draw the floor and axis ----*/
	glPushMatrix();
		DrawAxis();

		on_off_light(true);
		//draw_floor(-4.0f);
		on_off_light(false);
	glPopMatrix();

	//move to the base position
	glTranslatef(0, 0, 0);

	std::vector< std::vector<double> > point_list = get_point_list_vector();
	std::vector< Separator_item_t > separator_item_list = get_Separator_load_list_vector();
	/*-------Draw the loaded vertex which load by flex and bison. ----*/
	on_off_light(true);
	glPushMatrix();
			glScalef(1.0, 1.0, 1.0);
			int max_point = point_list.size();
			for(int i=0; i<max_point; i++){
					glPushMatrix();
							glTranslatef(point_list[i][0], point_list[i][1], point_list[i][2]);
							//gluSphere(sphere,  0.05,  8,  8);
					glPopMatrix();
			}
			on_off_light(false);

			/* debugging */
			glLineWidth(2.5);
			glColor3f(0.0, 0.0, 0.0);
			/* debugging */

			glPushMatrix();
					int max_Separator_item = separator_item_list.size();
					for(int i=0; i<max_Separator_item; i++){
							Separator_item_t it = separator_item_list[i];
							//int max_face_vertex = 0, j = 0;
							switch ( it.type ) {
									case Separator_item_t::s_LineSet:
											draw_lines(point_list, it.data.LineSetData);
											break;
									case Separator_item_t::s_FaceSet:
											draw_all_faces(point_list, it.data.FaceSetData);
											//on_off_light(true);
											//max_face_vertex = it.data.FaceSetData->size();
											//for(j=0; j<max_face_vertex; j++){
											//		glNormal3f(it.data.FaceSetData->at(j).normal[0],it.data.FaceSetData->at(j).normal[1],it.data.FaceSetData->at(j).normal[2]);
											//		draw_faces(point_list, it.data.FaceSetData->at(j));
											//}
											//on_off_light(false);
											break;
									case Separator_item_t::s_Material:
											set_material(it.data.MaterialData);
											break;
									case Separator_item_t::s_nulldata:
											break;
									default:
											break;
							}
					}
			glPopMatrix();
	glPopMatrix();

	/*------- Swap the back buffer to the front --------*/
	glutSwapBuffers();
	glFlush(); /*---- Display the results----*/
}

/*------- window size changed --------*/
void window_size_changed(int w, int h)
{
	/*------- draw all things with full window --------*/
	glViewport(0, 0, w, h);


	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	if (is_Perspective) gluPerspective(90.0, (double) w/ (double) h, 1.5, 500.0);
	else {
			if (w>h)
				glOrtho(-10.0, 10.0, -10.0*(float)h / (float)w, 10.0*(float)h / (float)w,
					0.50, 500.0);
			else
				glOrtho(-10.0*(float)w / (float)h, 10.0*(float)w / (float)h, -10.0, 10.0,
					0.50, 500.0);
	}
	width = w; height = h;

	/*---Trigger Display event for redisplay window*/
	glutPostRedisplay();
}


void keydown(unsigned char key, int x, int y)
{
	bool chang_view = false;
	if (key == 'q' || key == 'Q') exit(0);
	if (key == 'f') { polar_pos[0] +=  1; chang_view = true; }
	if (key == 'F') { polar_pos[0] += 10; chang_view = true; }
	if (key == 'h') { polar_pos[0] -=  1; chang_view = true; }
	if (key == 'H') { polar_pos[0] -= 10; chang_view = true; }
	if (key == 't') { polar_pos[1] +=  1; chang_view = true; }
	if (key == 'T') { polar_pos[1] += 10; chang_view = true; }
	if (key == 'g') { polar_pos[1] -=  1; chang_view = true; }
	if (key == 'G') { polar_pos[1] -= 10; chang_view = true; }

	if (key == 'a') { focus[0] -=  0.1; chang_view = true; }
	if (key == 'A') { focus[0] -= 1; chang_view = true; }
	if (key == 'd') { focus[0] +=  0.1; chang_view = true; }
	if (key == 'D') { focus[0] += 1; chang_view = true; }
	if (key == 'z') { focus[1] +=  0.1; chang_view = true; }
	if (key == 'Z') { focus[1] += 1; chang_view = true; }
	if (key == 'x') { focus[1] -=  0.1; chang_view = true; }
	if (key == 'X') { focus[1] -= 1; chang_view = true; }
	if (key == 'w') { focus[2] -=  0.1; chang_view = true; }
	if (key == 'W') { focus[2] -= 1; chang_view = true; }
	if (key == 's') { focus[2] +=  0.1; chang_view = true; }
	if (key == 'S') { focus[2] += 1; chang_view = true; }
	if (key == 'c' || key == 'C') { focus[0] = focus[1] = focus[2] = 0; chang_view = true; }
	if (key == 'v') { dir -= 0.1; chang_view = true; }
	if (key == 'V') { dir -= 1; chang_view = true; }
	if (key == 'b') { dir += 0.1; chang_view = true; }
	if (key == 'B') { dir += 1; chang_view = true; }
	if (chang_view) { update_eye_pos(); setting_light();}
}

int symbol_compare(const std::string left, const std::string right){
		std::string left_str(left), right_str(right);
		for ( std::string::iterator it=left_str.begin(); it!=left_str.end(); ++it)
				*it = ((*it >= 'a') ? ((*it) - 'a' + 'A') : (*it));
		for ( std::string::iterator it=right_str.begin(); it!=right_str.end(); ++it)
				*it = ((*it >= 'a') ? ((*it) - 'a' + 'A') : (*it));
		return left_str.compare(right_str);
}

int glmain(int argc, char **argv)
{
	/*-----Initialize the GLUT environment-------*/
	glutInit(&argc, argv);

	/*-----Depth buffer is used, be careful !!!----*/
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);

	glutInitWindowSize(500, 500);
//std::string SceneInfo(""), Title("Unnamed"), ViewerInfo("");
	std::map<std::string,def_dataType> symbol_table = get_def_datas();
	for (std::map<std::string,def_dataType>::iterator it=symbol_table.begin(); it!=symbol_table.end(); ++it){
 			std::string def_name = it->first;
 			def_dataType def_data = it->second;
			if(!def_data.str)continue;
			if( symbol_compare(def_name, "Title") == 0 ){
					Title = *def_data.str;
					continue;
			}
			if( symbol_compare(def_name, "BackgroundColor") == 0 ){
					sscanf(def_data.str->c_str(), "%g %g %g", &BackgroundColor[0], &BackgroundColor[1], &BackgroundColor[2]);
					BackgroundColor[3] = 1.0f;
					continue;
			}
			if( symbol_compare(def_name, "SceneInfo") == 0 ){
					SceneInfo = *def_data.str;
					continue;
			}
			if( symbol_compare(def_name, "Viewer") == 0 ){
					ViewerInfo = *def_data.str;
					continue;
			}
  }
	glutCreateWindow(Title.c_str());

	glutDisplayFunc(display);
	glutReshapeFunc(window_size_changed);
	glutKeyboardFunc(keydown);

	std::vector< std::vector<double> > point_list = get_point_list_vector();
	std::vector< Separator_item_t > separator_item_list = get_Separator_load_list_vector();

	int max_Separator_item = separator_item_list.size();
	for(int i=0; i<max_Separator_item; i++){
			Separator_item_t it = separator_item_list[i];
			if(it.type == Separator_item_t::s_FaceSet){
					 std::vector<face_item_t> *Face_iterator = it.data.FaceSetData;
					 int max_face_vertex = Face_iterator->size();
					 for(int j=0; j<max_face_vertex; j++){
						 	if(Face_iterator->at(j).point_indexs.size())calc_cross(point_list, Face_iterator->at(j));
					 }
			}
	}


	myinit();      /*---Initialize other state varibales----*/

				   /*----Associate callback func's whith events------*/

	setting_light();
	glutMainLoop();
	return 0;
}
