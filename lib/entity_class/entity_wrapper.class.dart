part of '../main.dart';

class EntityWrapper {

  String displayName;
  String icon;
  Entity entity;

  EntityWrapper({this.entity, String icon, String displayName}) {
    this.icon = icon ?? entity.icon;
    this.displayName = displayName ?? entity.displayName;
  }

}