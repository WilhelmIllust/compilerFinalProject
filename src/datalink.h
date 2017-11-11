#pragma once

#ifndef DATALINK_H
#define DATALINK_H

#define _CRT_SECURE_NO_WARNINGS

struct indexed_line_t {
    int start;
    int end;
};

struct Material_data_t{
    double ambientColor[4];
    double diffuseColor[4];
    double specularColor[4];
    double emissiveColor[4];
    double ambientIntensity;
    double shininess;
    double transparency;
};

struct face_item_t {
    double normal[3];
    bool is_convex;
    std::vector<int> point_indexs;
};

struct cell_Separator_item_t {
    int dimension;
    std::vector< std::vector<int> > cells;
};

struct Separator_item_t {
    enum Separator_item_type_t : unsigned char {
        s_nulldata, s_LineSet, s_FaceSet, s_CellSet, s_Material
    } type;
    union Separator_item_data_t {
        std::vector< indexed_line_t > *LineSetData;
        std::vector<face_item_t> *FaceSetData;
        cell_Separator_item_t *CellSetData;
        Material_data_t *MaterialData;
    } data;
};


struct def_dataType{
    bool is_Light_data;
    bool is_Color_type;
    std::string *str;
};

struct light_struct {
    bool enabled;
    double intensity;
    double color[4];
    double position[4];
    double drop_off_rate;
    double cut_off_angle;
  };
double* cross(double vec1[], double vec2[], double vec3[]);
double* fill_vec3_from_vec4(double desc[3], double src[4]);
int symbol_compare(const std::string left, const std::string right);
std::vector<light_struct> get_light_lists();
std::vector< std::vector<double> > get_point_list_vector();
std::map<std::string,def_dataType> get_def_datas();
std::vector< Separator_item_t > get_Separator_load_list_vector();
int glmain(int argc, char* argv[]);

#endif
