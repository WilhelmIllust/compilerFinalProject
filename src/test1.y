%{
  #include <iostream>
  #include <sstream>
  #include <string.h>
  #include <stdio.h>
  #include <map>
  #include <cmath>
  #include <algorithm>
  #include <vector>
  //FOR OTHER FILE
  #include "datalink.h"

  void yyerror(char *);
  extern int yylex();
  extern int yyparse();

  struct number_union{
    bool is_float;
    union int_float {
      double float_num;
      int int_num;
    } data;
  };
  static std::map<std::string,def_dataType> def_datas;
  static std::vector<number_union> number_load_buffer;

  static std::vector<int> integer_load_buffer;

  static std::vector< std::vector<int> > point_index_load_buffer;
  static std::vector< std::vector<int> > point_index_list_vector;

  static std::vector< Separator_item_t > Separator_load_list_vector;

  static Material_data_t Material_data_buffer;

  static std::vector< std::vector<double> > point_coord_load_buffer;
  static std::vector< std::vector<double> > point_list_vector;
  static light_struct light_buffer;
  static std::vector<light_struct> light_lists;
  static std::string now_loadded_define("NULL");
  static int light_count = 0;
  static int load_dim = 0;
  static int cell_dim = 0;
  namespace ShapeHint {
      enum ShapeHintEnum{ vertexOrdering = 0, shapeType, faceType };
      std::string ShapeHintStr[] = {"vertexOrdering", "shapeType", "faceType"};
      std::string ShapeHintEnumStr[3][3] = {
                                              {"UNKNOWN_ORDERING", "CLOCKWISE", "COUNTERCLOCKWISE"},
                                              {"UNKNOWN_SHAPE_TYPE", "SOLID", ""},
                                              {"UNKNOWN_FACE_TYPE", "CONVEX", "NONCONVEX"}
                                           };
      enum shapeTypeEnum{ UNKNOWN_SHAPE_TYPE = 0, SOLID };
      std::string shapeTypeStr[] = {"UNKNOWN_SHAPE_TYPE", "SOLID"};

      enum faceTypeEnum{ UNKNOWN_FACE_TYPE = 0, CONVEX, NONCONVEX };
      std::string faceTypeStr[] = {"UNKNOWN_FACE_TYPE", "CONVEX", "NONCONVEX"};

      enum vertexOrderingEnum{ UNKNOWN_ORDERING = 0, CLOCKWISE, COUNTERCLOCKWISE };
      std::string vertexOrderingStr[] = {"UNKNOWN_ORDERING", "CLOCKWISE", "COUNTERCLOCKWISE"};
  }
  struct ShapeHintData {
      ShapeHint::vertexOrderingEnum vertexOrdering;
      ShapeHint::faceTypeEnum faceType;
      ShapeHint::shapeTypeEnum shapeType;
      double creaseAngle;
  };
  static ShapeHintData shapeHint_buffer;
  std::vector<light_struct> get_light_lists(){
      return light_lists;
  }
  std::vector< std::vector<double> > get_point_list_vector(){
      return point_list_vector;
  }
  std::map<std::string,def_dataType> get_def_datas(){
      return def_datas;
  }
  std::vector< Separator_item_t > get_Separator_load_list_vector(){
      return Separator_load_list_vector;
  }
  void fill_color_data_d(double desc[4], double src[4]){
      desc[0] = src[0];
      desc[1] = src[1];
      desc[2] = src[2];
      desc[3] = src[3];
  }
  double* subtract(double vec1[], double vec2[], double vec3[])
  {
  		vec3[0] = vec2[0] - vec1[0];
  		vec3[1] = vec2[1] - vec1[1];
  		vec3[2] = vec2[2] - vec1[2];
  		return vec3;
  }
  double* fill_vec3_from_vec4(double desc[3], double src[4])
  {
  		desc[0] = src[0];
  		desc[1] = src[1];
  		desc[2] = src[2];
  		return desc;
  }
  void print_color_data_d(double desc[4]){
      std::cout << "color( " << desc[0] << ", " << desc[1] << ", " << desc[2] << ", " << desc[3] << " )" << std::endl;
  }
  void clean_shapeHint_buffer(){
      shapeHint_buffer.vertexOrdering = (ShapeHint::vertexOrderingEnum)0;
      shapeHint_buffer.shapeType = (ShapeHint::shapeTypeEnum)0;
      shapeHint_buffer.faceType = (ShapeHint::faceTypeEnum)0;
      shapeHint_buffer.creaseAngle = (double)0;
  }
  void clean_light_buffer(){
      light_buffer.enabled = true;
      light_buffer.intensity = 0.0;
      light_buffer.color[0] = light_buffer.color[1] = light_buffer.color[2] = light_buffer.color[3] = 0.5;
      light_buffer.position[0] = light_buffer.position[1] = light_buffer.position[2] = light_buffer.position[3] = 0.0;
      light_buffer.intensity = 0.0;
      light_buffer.drop_off_rate = 0.0;
      light_buffer.cut_off_angle = 0.0;
  }
  void clean_material_buffer(){
      Material_data_buffer.ambientIntensity = 1.0;
      Material_data_buffer.shininess = 0;
      Material_data_buffer.transparency = 0;
      Material_data_buffer.ambientColor[0] = Material_data_buffer.ambientColor[1] = Material_data_buffer.ambientColor[2] = (Material_data_buffer.ambientColor[3] = 1.0) - 0.7;
      Material_data_buffer.emissiveColor[0] = Material_data_buffer.emissiveColor[1] = Material_data_buffer.emissiveColor[2] = Material_data_buffer.emissiveColor[3] = 0.0;
      Material_data_buffer.specularColor[0] = Material_data_buffer.specularColor[1] = Material_data_buffer.specularColor[2] = Material_data_buffer.specularColor[3] = 0.0;
      Material_data_buffer.diffuseColor[0] = Material_data_buffer.diffuseColor[1] = Material_data_buffer.diffuseColor[2] = Material_data_buffer.diffuseColor[3] = 0.0;
  }
  void store_material_buffer(){
      Material_data_buffer.shininess *= 128;
      if(Material_data_buffer.shininess > 128)Material_data_buffer.shininess = 128;
      if(Material_data_buffer.shininess < 0)Material_data_buffer.shininess = 0;

      if((Material_data_buffer.specularColor[0] == Material_data_buffer.specularColor[1]) && (Material_data_buffer.specularColor[2] == Material_data_buffer.specularColor[0]) &&
      ( Material_data_buffer.specularColor[0] == 0 )){
          fill_color_data_d(Material_data_buffer.specularColor, Material_data_buffer.diffuseColor);
      }
  }
  void set_light_buffer_color(double color_vec[4]){
      for(int i=0; i<4; i++)light_buffer.color[i] = color_vec[i];
  }
  void set_light_buffer_position(double position[4]){
      for(int i=0; i<4; i++)light_buffer.position[i] = position[i];
  }
%}

%union{ int i; std::string *s; double f; bool b;}
%token<f> NUMBER FLOAT_NUMBER
%token<s> ID STR
%token COMMA left_curly_bracket right_curly_bracket left_square_bracket right_square_bracket
%token<s> Color_type Light_data
%token STRING_TYPE INFO_TYPE SHAPE_HINTS_TYPE
%token<b> BOOLEAN_VALUE
%token define_data Separator_data Material_data Point_data coordIndex_data intensity_data
%token LIGHT_ON DROP_OFF_RATE CUT_OFF_ANGLE
%token<b> VERTEX_HOMO
%token<i> SHAPE_HINTS_ENUM VERTEX_ORDERING_ENUM SHAPE_TYPE_ENUM FACE_TYPE_ENUM
%token<s> SHAPE_HINTS_NUMBER Index_data
%token<i> Coordinate_data
%token<s> Material_info

%%
vrml_file       : vrml_item_list
                ;
vrml_item_list  : vrml_item_list vrml_item
                | vrml_item
                ;
vrml_item       : stated
                | sp
                ;
stated          : define_data variable_name INFO  {
                                                      std::cout << std::endl;
                                                      now_loadded_define = "NULL";
                                                  }
                | INFO                            {
                                                      std::cout << std::endl;
                                                      now_loadded_define = "JUSTDATA_";
                                                  }
                ;
INFO            : INFO_TYPE left_curly_bracket INFO_VALUE_LISTS right_curly_bracket
                | SHAPE_HINTS_TYPE left_curly_bracket SHAPE_HINTS_TYPE_VALUE_LISTS right_curly_bracket
                | Light_data left_curly_bracket LIGHT_DATA_VALUE_LISTS right_curly_bracket  {
                                                                                                light_lists.push_back(light_buffer);
                                                                                                int light_temp_type = ((light_buffer.position[3] > 0.01) ?
                                                                                                ((light_buffer.cut_off_angle > 0.01 &&
                                                                                                light_buffer.cut_off_angle < 360) ? 2 : 1 )
                                                                                                : 0);// 0=Directional, 1=Point, 2=Spot;

                                                                                                std::cout << "light-" << light_lists.size() << " : ";
                                                                                                std::cout << ((light_buffer.position[3] > 0.01) ?
                                                                                                ((light_buffer.cut_off_angle > 0.01 &&
                                                                                                light_buffer.cut_off_angle < 360) ? "Spot" : "Point" )
                                                                                                : "Directional") << " light added" << std::endl;

                                                                                                if(light_temp_type > 0) std::cout << "\tlocation = ( ";
                                                                                                else std::cout << "\tdirection = < ";
                                                                                                std::cout << light_buffer.position[0] << ", ";
                                                                                                std::cout << light_buffer.position[1] << ", ";
                                                                                                std::cout << light_buffer.position[2];
                                                                                                if(light_temp_type > 0) std::cout  << " )" << std::endl;
                                                                                                else std::cout  << " >" << std::endl;

                                                                                                std::cout << "\tcolor = [";
                                                                                                std::cout << light_buffer.color[0] << ", ";
                                                                                                std::cout << light_buffer.color[1] << ", ";
                                                                                                std::cout << light_buffer.color[2] << " ]" << std::endl;

                                                                                                std::cout << std::endl;
                                                                                            }
                ;

INFO_VALUE_LISTS : INFO_VALUE_LIST
                | /* epsilon */     {
                                        std::string msg("Error! : define but is null.");
                                        if(now_loadded_define.compare("NULL") == 0) yyerror(const_cast<char*>(msg.c_str()));
                                        def_datas[now_loadded_define].str = NULL;
                                    }
                ;
SHAPE_HINTS_TYPE_VALUE_LISTS : SHAPE_HINTS_TYPE_VALUE_LIST
                             |  /* epsilon */
                             ;
LIGHT_DATA_VALUE_LISTS       : LIGHT_DATA_VALUE_LIST
                             |  /* epsilon */
                             ;

INFO_VALUE_LIST : INFO_VALUE_LIST INFO_VALUE
                | INFO_VALUE
                ;
SHAPE_HINTS_TYPE_VALUE_LIST : SHAPE_HINTS_TYPE_VALUE_LIST SHAPE_HINTS_TYPE_VALUE
                            | SHAPE_HINTS_TYPE_VALUE
                            ;
LIGHT_DATA_VALUE_LIST       : LIGHT_DATA_VALUE_LIST LIGHT_DATA_VALUE
                            | LIGHT_DATA_VALUE
                            ;

SHAPE_HINTS_TYPE_VALUE      : SHAPE_HINTS_ENUM VERTEX_ORDERING_ENUM {
                                                                        if( $1 != ShapeHint::vertexOrdering) {
                                                                          std::ostringstream ss;
                                                                          ss << "Error! : " << ShapeHint::vertexOrderingStr[$2];
                                                                          ss << " is not a member of " << ShapeHint::ShapeHintStr[$1];
                                                                          yyerror(const_cast<char*>(ss.str().c_str()));
                                                                          return -1;
                                                                        }
                                                                        shapeHint_buffer.vertexOrdering = (ShapeHint::vertexOrderingEnum)$2;
                                                                        std::cout << ShapeHint::ShapeHintStr[$1] << " = " << ShapeHint::vertexOrderingStr[$2] << std::endl;
                                                                    }
                            | SHAPE_HINTS_ENUM SHAPE_TYPE_ENUM      {
                                                                        if( $1 != ShapeHint::shapeType) {
                                                                          std::ostringstream ss;
                                                                          ss << "Error! : " << ShapeHint::shapeTypeStr[$2];
                                                                          ss << " is not a member of " << ShapeHint::ShapeHintStr[$1];
                                                                          yyerror(const_cast<char*>(ss.str().c_str()));
                                                                          return -1;
                                                                        }
                                                                        shapeHint_buffer.shapeType = (ShapeHint::shapeTypeEnum)$2;
                                                                        std::cout << ShapeHint::ShapeHintStr[$1] << " = " << ShapeHint::shapeTypeStr[$2] << std::endl;
                                                                    }
                            | SHAPE_HINTS_ENUM FACE_TYPE_ENUM       {
                                                                        if( $1 != ShapeHint::faceType) {
                                                                          std::ostringstream ss;
                                                                          ss << "Error! : " << ShapeHint::faceTypeStr[$2];
                                                                          ss << " is not a member of " << ShapeHint::ShapeHintStr[$1];
                                                                          yyerror(const_cast<char*>(ss.str().c_str()));
                                                                          return -1;
                                                                        }
                                                                        shapeHint_buffer.faceType = (ShapeHint::faceTypeEnum)$2;
                                                                        std::cout << ShapeHint::ShapeHintStr[$1] << " = " << ShapeHint::faceTypeStr[$2] << std::endl;
                                                                    }
                            | SHAPE_HINTS_NUMBER FLOAT_NUMBER       {
                                                                        std::cout << *$1 << " = " << $2 << std::endl;
                                                                        shapeHint_buffer.creaseAngle = $2;
                                                                    }
                            | SHAPE_HINTS_NUMBER NUMBER             {
                                                                        std::cout << *$1 << " = " << $2 << std::endl;
                                                                        shapeHint_buffer.creaseAngle = $2;
                                                                    }
                            ;
LIGHT_DATA_VALUE            : LIGHT_ON BOOLEAN_VALUE                  {
                                                                          light_buffer.enabled = $2;
                                                                          number_load_buffer.clear();
                                                                      }
                            | VERTEX_HOMO G_NUMBER G_NUMBER G_NUMBER  {
                                                                          double temp[4];
                                                                          for(int i = 0; i < 3; i++){
                                                                             number_union it = number_load_buffer[i];
                                                                             if(it.is_float) temp[i] = it.data.float_num;
                                                                             else temp[i] = (double)(it.data.int_num);
                                                                          }
                                                                          temp[3] = (($1) ? 1.0 : 0.0);
                                                                          set_light_buffer_position(temp);
                                                                          number_load_buffer.clear();
                                                                      }
                            | Color_type G_NUMBER G_NUMBER G_NUMBER   {
                                                                          double temp[4];
                                                                          for(int i = 0; i < 3; i++){
                                                                             number_union it = number_load_buffer[i];
                                                                             if(it.is_float) temp[i] = it.data.float_num;
                                                                             else temp[i] = (double)(it.data.int_num);
                                                                          }
                                                                          temp[3] = 1.0;
                                                                          set_light_buffer_color(temp);
                                                                          number_load_buffer.clear();
                                                                      }
                            | DROP_OFF_RATE G_NUMBER                  {
                                                                          double temp;
                                                                          number_union it = number_load_buffer[0];
                                                                          if(it.is_float) temp = it.data.float_num;
                                                                          else temp = (double)(it.data.int_num);
                                                                          light_buffer.drop_off_rate = temp;
                                                                          number_load_buffer.clear();
                                                                      }
                            | CUT_OFF_ANGLE G_NUMBER                  {
                                                                          double temp;
                                                                          number_union it = number_load_buffer[0];
                                                                          if(it.is_float) temp = it.data.float_num;
                                                                          else temp = (double)(it.data.int_num);
                                                                          light_buffer.cut_off_angle = temp;
                                                                          number_load_buffer.clear();
                                                                      }
                            | intensity_data G_NUMBER                 {
                                                                          double temp;
                                                                          number_union it = number_load_buffer[0];
                                                                          if(it.is_float) temp = it.data.float_num;
                                                                          else temp = (double)(it.data.int_num);
                                                                          light_buffer.intensity  = temp;
                                                                          number_load_buffer.clear();
                                                                      }
                            ;
G_NUMBER                    : FLOAT_NUMBER                            {
                                                                         number_union temp;
                                                                         temp.is_float = true;
                                                                         temp.data.float_num = $1;
                                                                         number_load_buffer.push_back(temp);
                                                                      }
                            | NUMBER                                  {
                                                                         number_union temp;
                                                                         temp.is_float = false;
                                                                         temp.data.int_num = $1;
                                                                         number_load_buffer.push_back(temp);
                                                                      }
                            ;
INFO_VALUE      : STRING_TYPE STR {
                                    std::string msg("Error! : define but is null.");
                                    if(now_loadded_define.compare("NULL") == 0) yyerror(const_cast<char*>(msg.c_str()));
                                    def_dataType &def_data = def_datas[now_loadded_define];
                                    if(def_data.str){
                                        *(def_data.str) += "\n" + *new std::string(*$2);
                                    }else{
                                        std::cout << "the \"" << now_loadded_define << "\" is \"" << *$2 << "\"";
                                        def_data.str = new std::string(*$2);
                                        if(def_datas[now_loadded_define].is_Light_data) std::cout << ", and it is a light data.";
                                        else if(def_datas[now_loadded_define].is_Color_type) std::cout << ", and it is a color type.";
                                        std::cout << std::endl;
                                    }
                                }
                ;
variable_name   : ID          {
                                now_loadded_define = *new std::string(*$1);
                            }
                | Light_data  {
                                now_loadded_define = *new std::string(*$1);
                                def_datas[*$1].is_Light_data = true;
                            }
                | Color_type  {
                                now_loadded_define = *new std::string(*$1);
                                def_datas[*$1].is_Color_type = true;
                            }
                ;
sp              : Separator_data left_curly_bracket st right_curly_bracket         {
                                                              printf("ok sp is read\n");
                                                              int max_Separator_item = Separator_load_list_vector.size();
                                                              std::cout << "Separator items : " << max_Separator_item << std::endl;
                                                              for(int i=0; i<max_Separator_item; i++){
                                                                  Separator_item_t it = Separator_load_list_vector[i];
                                                                  std::vector< indexed_line_t > * it_lineset = NULL;
                                                                  std::vector< face_item_t > * it_faceset = NULL;
                                                                  cell_Separator_item_t * it_cellset = NULL;
                                                                  Material_data_t * it_mterial = NULL;
                                                                  std::vector<int> * it_indexset = NULL;
                                                                  indexed_line_t line_buffer;
                                                                  std::cout << (i + 1) << ": ";
                                                                  int max_SetData = 0, max_SetItem = 0;
                                                                  switch ( it.type ) {
                                                                      case Separator_item_t::s_LineSet:
                                                                          std::cout << "LineSet = " ;
                                                                          it_lineset = it.data.LineSetData;
                                                                          max_SetData = it_lineset->size();
                                                                          for(int j = 0; j<max_SetData; j++){
                                                                              line_buffer = it_lineset->at(j);
                                                                              std::cout << "[ " << line_buffer.start << " -> " << line_buffer.end << " ]";
                                                                              if(j < max_SetData - 1) std::cout << ", ";
                                                                          }
                                                                          std::cout << std::endl;
                                                                          break;
                                                                      case Separator_item_t::s_FaceSet:
                                                                          std::cout << "FaceSet = { " ;
                                                                          it_faceset = it.data.FaceSetData;
                                                                          max_SetData = it_faceset->size();
                                                                          for(int j = 0; j<max_SetData; j++){
                                                                              it_indexset = &(it_faceset->at(j).point_indexs);
                                                                              max_SetItem = it_indexset->size();
                                                                              if (shapeHint_buffer.vertexOrdering == ShapeHint::UNKNOWN_ORDERING)
                                                                              if (j % 2)continue;
                                                                              if(max_SetItem){
                                                                                  std::cout << "{ ";
                                                                                  for(int k = 0; k<max_SetItem; k++){
                                                                                      std::cout << it_indexset->at(k);
                                                                                      std::cout << ((k >= max_SetItem - 1) ? "} " : ", ");
                                                                                  }
                                                                                  if ((shapeHint_buffer.vertexOrdering == ShapeHint::UNKNOWN_ORDERING)) {
                                                                                      if (j < max_SetData - 2) std::cout << ", ";
                                                                                  } else {
                                                                                      if (j < max_SetData - 1) std::cout << ", ";
                                                                                  }
                                                                              }
                                                                          }
                                                                          std::cout << " }" << std::endl;
                                                                          break;
                                                                      case Separator_item_t::s_CellSet:
                                                                          std::cout << "CellSet = " ;
                                                                          it_cellset = it.data.CellSetData;
                                                                          max_SetData = it_cellset->cells.size();
                                                                          std::cout << "{ dimension = " << it_cellset->dimension << " ,";
                                                                          for(int j = 0; j<max_SetData; j++){
                                                                              it_indexset = &(it_cellset->cells[j]);
                                                                              max_SetItem = it_indexset->size();
                                                                              if(max_SetItem){
                                                                                  std::cout << "{ ";
                                                                                  for(int k = 0; k<max_SetItem; k++){
                                                                                      std::cout << it_indexset->at(k);
                                                                                      std::cout << ((k >= max_SetItem - 1) ? "} " : ", ");
                                                                                  }
                                                                                  if(j < max_SetData - 1) std::cout << ", ";
                                                                              }
                                                                          }
                                                                          std::cout << " }" << std::endl;
                                                                          break;
                                                                      case Separator_item_t::s_Material:
                                                                          std::cout << "MaterialData = " << std::endl;
                                                                          it_mterial = it.data.MaterialData;
                                                                          std::cout << "\tshininess = " << it_mterial->shininess << std::endl;
                                                                          std::cout << "\tambientIntensity = " << it_mterial->ambientIntensity << std::endl;
                                                                          std::cout << "\ttransparency = " << it_mterial->transparency << std::endl;
                                                                          std::cout << "\tambientColor = ";
                                                                          print_color_data_d(it_mterial->ambientColor);
                                                                          std::cout << "\tdiffuseColor = ";
                                                                          print_color_data_d(it_mterial->diffuseColor);
                                                                          std::cout << "\tspecularColor = ";
                                                                          print_color_data_d(it_mterial->specularColor);
                                                                          std::cout << "\temissiveColor = ";
                                                                          print_color_data_d(it_mterial->emissiveColor);
                                                                          std::cout << "\tMaterial data"<< std::endl;
                                                                          break;
                                                                      case Separator_item_t::s_nulldata:
                                                                          break;
                                                                      default:
                                                                          break;
                                                                  }
                                                              }
                                                          }
                ;
st              : Coord_data stc
                | Mater_data stm
                ;
stc             : Mater_data stmc
                | Coord_data stc
  	            ;
stm             : Coord_data stmc
                | Indexed_data stm
                | Mater_data stm
                ;
stmc            : Coord_data stmc
                | Mater_data stmc
                | Indexed_data stmc
                | /* epsilon */
                ;
Coord_data      : Coordinate_data left_curly_bracket Point_data left_square_bracket mixed_number_lists right_square_bracket right_curly_bracket        {
                                              int dim_tmp = $1;
                                              std::vector<double> temp;
                                              int buf_size = number_load_buffer.size();
                                              if(buf_size > 0){
                                                  if(load_dim != buf_size){
                                                       std::ostringstream ss;
                                                       ss << "stynax error! : " << "old dimension is " << load_dim << ", but load " << buf_size << " numbers.";
                                                       yyerror(const_cast<char*>(ss.str().c_str()));
                                                       return -1;
                                                  }
                                                  for(int i = 0; i < buf_size; i++){
                                                      double it;
                                                      if(number_load_buffer[i].is_float)it = number_load_buffer[i].data.float_num;
                                                      else it = (double)(number_load_buffer[i].data.int_num);
                                                      temp.push_back(it);
                                                  }
                                                  point_coord_load_buffer.push_back(temp);
                                                  number_load_buffer.clear();
                                              }
                                              std::cout << "Coordinate, dimension = " << dim_tmp << std::endl;
                                              if(dim_tmp != load_dim){
                                                  std::ostringstream ss;
                                                  ss << "Syntax Error! : " << "Coordinate dimension is " << dim_tmp;
                                                  ss << " but loaded data is a " << load_dim << " dimensional data.";
                                                  yyerror(const_cast<char*>(ss.str().c_str()));
                                                  return -1;
                                              }
                                              int buffer_size = point_coord_load_buffer.size();
                                              std::vector<double> point_temp;
                                              for(int i=0; i<buffer_size; i++){
                                                int it_size = point_coord_load_buffer[i].size();
                                                for(int j=0; j<it_size; j++){
                                                  double it_value = point_coord_load_buffer[i][j];
                                                  point_temp.push_back(it_value);
                                                  std::cout << ((j == 0) ? "( " : "") << it_value << ((j < it_size - 1) ? " ," : " )");
                                                }
                                                if(i < buffer_size - 1) std::cout << ", ";
                                                else std::cout << std::endl;
                                                point_list_vector.push_back(point_temp);
                                                point_temp.clear();
                                              }
                                              point_coord_load_buffer.clear();
                                          }
                ;
Mater_data      : Material_data left_curly_bracket color_lists right_curly_bracket         {
                                              store_material_buffer();
                                              Material_data_t * material_data_temp = new Material_data_t;
                                              fill_color_data_d(material_data_temp->ambientColor, Material_data_buffer.ambientColor);
                                              fill_color_data_d(material_data_temp->diffuseColor, Material_data_buffer.diffuseColor);
                                              fill_color_data_d(material_data_temp->specularColor, Material_data_buffer.specularColor);
                                              fill_color_data_d(material_data_temp->emissiveColor, Material_data_buffer.emissiveColor);
                                              material_data_temp->ambientIntensity = Material_data_buffer.ambientIntensity;
                                              material_data_temp->shininess = Material_data_buffer.shininess;
                                              material_data_temp->transparency = Material_data_buffer.transparency;

                                              Separator_item_t Separator_load_buffer;
                                              Separator_load_buffer.type = Separator_item_t::s_Material;
                                              Separator_load_buffer.data.MaterialData = material_data_temp;
                                              Separator_load_list_vector.push_back(Separator_load_buffer);
                                              clean_material_buffer();
                                          }
                ;

color_lists     : color_list
                ;

color_list      : color_list color_item
                | color_item
                ;

color_item      : Color_type G_NUMBER G_NUMBER G_NUMBER {
                                              double temp[4];
                                              for(int i = 0; i < 3; i++){
                                                 number_union it = number_load_buffer[i];
                                                 if(it.is_float) temp[i] = it.data.float_num;
                                                 else temp[i] = (double)(it.data.int_num);
                                              }
                                              temp[3] = 1.0;
                                              if(symbol_compare(*$1, "ambientColor") == 0){
                                                  fill_color_data_d(Material_data_buffer.ambientColor, temp);
                                              }else if(symbol_compare(*$1, "diffuseColor") == 0){
                                                  fill_color_data_d(Material_data_buffer.diffuseColor, temp);
                                              }else if(symbol_compare(*$1, "specularColor") == 0){
                                                  fill_color_data_d(Material_data_buffer.specularColor, temp);
                                              }else if(symbol_compare(*$1, "emissiveColor") == 0){
                                                  fill_color_data_d(Material_data_buffer.emissiveColor, temp);
                                              }else{
                                                  std::ostringstream ss;
                                                  ss << "Syntax Error! : \"" << *$1;
                                                  ss << "\" is not a member of \"Material\" .";
                                                  yyerror(const_cast<char*>(ss.str().c_str()));
                                                  return -1;
                                              }
                                              number_load_buffer.clear();
                                          }
                | Material_info G_NUMBER  {
                                              double temp;
                                              number_union it = number_load_buffer[0];
                                              if(it.is_float) temp = it.data.float_num;
                                              else temp = (double)(it.data.int_num);

                                              if(symbol_compare(*$1, "ambientIntensity")){
                                                  Material_data_buffer.ambientIntensity = temp;
                                              }else if(symbol_compare(*$1, "shininess")){
                                                  Material_data_buffer.shininess = temp;
                                              }else if(symbol_compare(*$1, "transparency")){
                                                  Material_data_buffer.transparency = temp;
                                              }else{
                                                  std::ostringstream ss;
                                                  ss << "Syntax Error! : \"" << *$1;
                                                  ss << "\" is not a member of \"Material\" .";
                                                  yyerror(const_cast<char*>(ss.str().c_str()));
                                                  return -1;
                                              }
                                              number_load_buffer.clear();
                                          }
                ;

Indexed_data    : Index_data left_curly_bracket coordIndex_data left_square_bracket indexed_number_lists right_square_bracket right_curly_bracket        {
                                          std::cout << "Indexed data, the data is \"" << *$1 << "\" " << std::endl;

                                          int lose_buf_size = integer_load_buffer.size();
                                          if (lose_buf_size) point_index_load_buffer.push_back(integer_load_buffer);
                                          integer_load_buffer.clear();

                                          Separator_item_t Separator_load_buffer;
                                          bool cell_flag = (symbol_compare(*$1, "Cell") == 0);
                                          if((symbol_compare(*$1, "Line") == 0) || (cell_flag && cell_dim == 1)){
                                              indexed_line_t line_buffer;
                                              std::vector< indexed_line_t > point_index_line_list_vector;
                                              int buf_size = point_index_load_buffer.size();
                                              if(buf_size){
                                                  for(int i=0; i<buf_size; i++){
                                                      int line_check = point_index_load_buffer[i].size();
                                                      if(line_check != 2){
                                                          std::ostringstream ss;
                                                          ss << "Error! : " << "Line must have 2 vertex, but is " << line_check <<  " .";
                                                          yyerror(const_cast<char*>(ss.str().c_str()));
                                                          return -1;
                                                      }
                                                      line_buffer.start = point_index_load_buffer[i][0];
                                                      line_buffer.end = point_index_load_buffer[i][1];
                                                      point_index_line_list_vector.push_back(line_buffer);
                                                  }
                                              }
                                              Separator_load_buffer.type = Separator_item_t::s_LineSet;
                                              Separator_load_buffer.data.LineSetData = new std::vector< indexed_line_t >;
                                              Separator_load_buffer.data.LineSetData->insert(Separator_load_buffer.data.LineSetData->begin(),
                                                  point_index_line_list_vector.begin(), point_index_line_list_vector.end());
                                              Separator_load_list_vector.push_back(Separator_load_buffer);
                                              point_index_line_list_vector.clear();
                                              point_index_load_buffer.clear();
                                          }else if((symbol_compare(*$1, "Face") == 0) || (cell_flag && cell_dim == 2)){
                                              std::vector<face_item_t> *FaceSetData_buffer = new std::vector<face_item_t>;
                                              std::vector<int> face_buffer_anti;
                                              int buf_size = point_index_load_buffer.size();
                                              if(buf_size){
                                                  for(int i=0; i<buf_size; i++){
                                                      int face_index_count = point_index_load_buffer[i].size();
                                                      if (face_index_count < 3){
                                                          std::ostringstream ss;
                                                          ss << "Error! : " << "Face must have 3 vertex, but is " << face_index_count <<  " .";
                                                          yyerror(const_cast<char*>(ss.str().c_str()));
                                                          return -1;
                                                      }
                                                      face_item_t face_buffer, face_buffer_reverse;
                                                      bool is_conv = true;
                                                      if (shapeHint_buffer.faceType == ShapeHint::NONCONVEX)is_conv = false;
                                                      if (shapeHint_buffer.vertexOrdering == ShapeHint::UNKNOWN_ORDERING) {
                                                          face_buffer.point_indexs.clear();
                                                          face_buffer_reverse.point_indexs.clear();
                                                          for(int j = 0; j<face_index_count; j++){
                                                              face_buffer.point_indexs.push_back(point_index_load_buffer[i][j]);
                                                              face_buffer_reverse.point_indexs.push_back(point_index_load_buffer[i][face_index_count-1-j]);
                                                          }
                                                          face_buffer.is_convex = is_conv;
                                                          //std::cout << (face_buffer.is_convex ? "True" : "False") << std::endl;
                                                          face_buffer_reverse.is_convex = is_conv;
                                                          FaceSetData_buffer->push_back(face_buffer);
                                                          FaceSetData_buffer->push_back(face_buffer_reverse);
                                                          face_buffer.point_indexs.clear();
                                                          face_buffer_reverse.point_indexs.clear();
                                                      }else if(shapeHint_buffer.vertexOrdering == ShapeHint::COUNTERCLOCKWISE){
                                                          face_buffer.point_indexs.clear();
                                                          face_buffer.point_indexs.insert(face_buffer.point_indexs.begin(), point_index_load_buffer[i].begin(), point_index_load_buffer[i].end());
                                                          face_buffer.is_convex = is_conv;
                                                          FaceSetData_buffer->push_back(face_buffer);
                                                          face_buffer.point_indexs.clear();
                                                      }else if(shapeHint_buffer.vertexOrdering == ShapeHint::CLOCKWISE){
                                                          face_buffer.point_indexs.clear();
                                                          face_buffer.is_convex = is_conv;
                                                          for(int j = 0; j<face_index_count; j++)
                                                              face_buffer.point_indexs.push_back(point_index_load_buffer[i][face_index_count-1-j]);
                                                          FaceSetData_buffer->push_back(face_buffer);
                                                          face_buffer.point_indexs.clear();
                                                      }
                                                  }
                                              }
                                              Separator_load_buffer.type = Separator_item_t::s_FaceSet;
                                              Separator_load_buffer.data.FaceSetData = FaceSetData_buffer;
                                              Separator_load_list_vector.push_back(Separator_load_buffer);
                                              point_index_load_buffer.clear();
                                          }else if(cell_flag && cell_dim > 2){
                                              cell_Separator_item_t *cell_data_buffer = new cell_Separator_item_t;
                                              cell_data_buffer->dimension = cell_dim;
                                              int buf_size = point_index_load_buffer.size();
                                              if (buf_size){
                                                  for(int i=0; i<buf_size; i++){
                                                      cell_data_buffer->cells.push_back(point_index_load_buffer[i]);
                                                  }
                                              }
                                              Separator_load_buffer.type = Separator_item_t::s_CellSet;
                                              Separator_load_buffer.data.CellSetData = cell_data_buffer;
                                              Separator_load_list_vector.push_back(Separator_load_buffer);
                                              point_index_load_buffer.clear();
                                          }else{
                                              std::ostringstream ss;
                                              ss << "Syntax Error! : " << "Unknow Indexed type \"" << *$1 << "\" !";
                                              yyerror(const_cast<char*>(ss.str().c_str()));
                                              return -1;
                                          }
                                          cell_dim = 0;
                                        }
                ;

indexed_number_lists  : indexed_number_list
                      |  /* epsilon */
                      ;
indexed_number_list   : indexed_number_list indexed_numbers
                      | indexed_numbers
                      ;
indexed_numbers       : NUMBER            {
                                              if($1 < -2){
                                                  std::ostringstream ss;
                                                  ss << "Error! : " << "invalid index " << $1;
                                                  yyerror(const_cast<char*>(ss.str().c_str()));
                                                  return -1;
                                              }else if($1 == -2){
                                                  int buf_size = integer_load_buffer.size();
                                                  if (buf_size == 1){
                                                      cell_dim = integer_load_buffer[0];
                                                      if(cell_dim < 1){
                                                          std::ostringstream ss;
                                                          ss << "Error! : " << "invalid cell dimension number " << cell_dim;
                                                          yyerror(const_cast<char*>(ss.str().c_str()));
                                                          return -1;
                                                      }
                                                      std::cout << "cell dimension = " << cell_dim << std::endl;
                                                  }
                                                  else {
                                                      std::ostringstream ss;
                                                      ss << "Error! : " << "invalid index " << $1;
                                                      yyerror(const_cast<char*>(ss.str().c_str()));
                                                      return -1;
                                                  }
                                                  integer_load_buffer.clear();
                                              }else if($1 == -1){
                                                  int buf_size = integer_load_buffer.size();
                                                  if (buf_size) point_index_load_buffer.push_back(integer_load_buffer);
                                                  integer_load_buffer.clear();
                                              }else{
                                                  integer_load_buffer.push_back($1);
                                              }
                                          }
                      | COMMA
                      ;
mixed_number_lists  : mixed_number_list
                    |  /* epsilon */
                    ;
mixed_number_list   : mixed_number_list mixed_numbers
                    | mixed_numbers
                    ;
mixed_numbers       : NUMBER              {
                                              number_union temp;
                                              temp.is_float = false;
                                              temp.data.int_num = $1;
                                              number_load_buffer.push_back(temp);
                                          }
                    | FLOAT_NUMBER        {
                                              number_union temp;
                                              temp.is_float = true;
                                              temp.data.float_num = $1;
                                              number_load_buffer.push_back(temp);
                                          }
                    | COMMA               {
                                              std::vector<double> temp;
                                              int buf_size = number_load_buffer.size();
                                              if(load_dim == 0)load_dim = buf_size;
                                              if(load_dim != buf_size){
                                                 std::ostringstream ss;
                                                 ss << "stynax error! : " << "old dimension is " << load_dim << ", but load " << buf_size << " numbers.";
                                                 yyerror(const_cast<char*>(ss.str().c_str()));
                                                 return -1;
                                              }
                                              for(int i = 0; i < buf_size; i++){
                                                  double it;
                                                  if(number_load_buffer[i].is_float)it = number_load_buffer[i].data.float_num;
                                                  else it = (double)(number_load_buffer[i].data.int_num);
                                                  temp.push_back(it);
                                              }
                                              if(buf_size) point_coord_load_buffer.push_back(temp);
                                              number_load_buffer.clear();
                                         }
                    ;
%%
void yyerror(char *s) {
    std::cout << "[ERROR!] " << s << std::endl;
}
extern FILE* yyin;
int main(int argc, char** argv){
     if(argc==2){
         yyin = fopen(argv[1], "r");
         if(!yyin){
             fprintf(stderr, "can't read file %s\n", argv[1]);
             return 1;
         }
     }
    clean_light_buffer();
    clean_material_buffer();
    int result =  yyparse();
     std::cout << "load complete!"  << "( yyparse return " << result << ")"<< std::endl << std::endl;
     if(result){
       std::cout << " but the source code has parsing error! \n this program will exit." << std::endl;
       exit(0);
     }
     std::cout << " ===== Symbol Table ===== " << std::endl;
     for (std::map<std::string,def_dataType>::iterator it=def_datas.begin(); it!=def_datas.end(); ++it){
        std::string def_name = it->first;
        def_dataType def_data = it->second;
        std::cout << "define \"" << def_name << "\"";
        if(def_data.is_Light_data) std::cout << " (light)";
        else if(def_data.is_Color_type) std::cout << " (color)";
        std::cout << " : " << std::endl;
        if(def_data.str) std::cout << "\t" << "=" << *(def_data.str) << std::endl;
     }
     std::cout << std::endl;
    std::cout << " ===== drawing the polytope ===== " << std::endl;
     if(point_list_vector.size()){
        if(point_list_vector[0].size() != 3){
            std::cout << std::endl;
            std::cout << "sorry~ but the  " << point_list_vector[0].size() << " dimensional polytope rendering " << std::endl;
            std::cout << " are not yet implemented!" << std::endl;
            std::cout << "so the program will exit." << std::endl;
            exit(0);
        }
     }
     std::cout << " ===== initialize the open GL ===== " << std::endl;
     glmain(argc, argv);
     return 0;
}
