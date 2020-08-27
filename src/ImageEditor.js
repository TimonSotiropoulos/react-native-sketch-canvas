"use strict";

import React from "react";
import PropTypes from "prop-types";
import ReactNative, {
    requireNativeComponent,
    NativeModules,
    UIManager,
    PanResponder,
    PixelRatio,
    Platform,
    ViewPropTypes,
    processColor
} from "react-native";
import { requestPermissions } from "./handlePermissions";

const RNImageEditor = requireNativeComponent("RNImageEditor", ImageEditor, {
    nativeOnly: {
        nativeID: true,
        onChange: true
    }
});
const ImageEditorManager = NativeModules.RNImageEditorManager || {};

const PATH = 'path';
const SHAPE = 'shape';

class ImageEditor extends React.Component {
    static propTypes = {
        style: ViewPropTypes.style,
        strokeColor: PropTypes.string,
        strokeWidth: PropTypes.number,
        onPathsChange: PropTypes.func,
        onStrokeStart: PropTypes.func,
        onStrokeChanged: PropTypes.func,
        onStrokeEnd: PropTypes.func,
        onSketchSaved: PropTypes.func,
        onShapeSelectionChanged: PropTypes.func,
        shapeConfiguration: PropTypes.shape({
            shapeBorderColor: PropTypes.string,
            shapeBorderStyle: PropTypes.string,
            shapeBorderStrokeWidth: PropTypes.number,
            shapeColor: PropTypes.string,
            shapeStrokeWidth: PropTypes.number
        }),
        user: PropTypes.string,
        scale: PropTypes.number,

        touchEnabled: PropTypes.bool,

        text: PropTypes.arrayOf(
            PropTypes.shape({
                text: PropTypes.string,
                font: PropTypes.string,
                fontSize: PropTypes.number,
                fontColor: PropTypes.string,
                overlay: PropTypes.oneOf(["TextOnSketch", "SketchOnText"]),
                anchor: PropTypes.shape({ x: PropTypes.number, y: PropTypes.number }),
                position: PropTypes.shape({ x: PropTypes.number, y: PropTypes.number }),
                coordinate: PropTypes.oneOf(["Absolute", "Ratio"]),
                alignment: PropTypes.oneOf(["Left", "Center", "Right"]),
                lineHeightMultiple: PropTypes.number
            })
        ),
        localSourceImage: PropTypes.shape({
            filename: PropTypes.string,
            directory: PropTypes.string,
            mode: PropTypes.oneOf(["AspectFill", "AspectFit", "ScaleToFill"])
        }),

        permissionDialogTitle: PropTypes.string,
        permissionDialogMessage: PropTypes.string
    };

    static defaultProps = {
        style: null,
        strokeColor: "#000000",
        strokeWidth: 3,
        onPathsChange: () => {},
        onStrokeStart: () => {},
        onStrokeChanged: () => {},
        onStrokeEnd: () => {},
        onSketchSaved: () => {},
        onShapeSelectionChanged: () => {},
        shapeConfiguration: {
            shapeBorderColor: "transparent",
            shapeBorderStyle: "Dashed",
            shapeBorderStrokeWidth: 1,
            shapeColor: "#000000",
            shapeStrokeWidth: 3
        },
        user: null,
        scale: 1,

        touchEnabled: true,

        text: null,
        localSourceImage: null,

        permissionDialogTitle: "",
        permissionDialogMessage: ""
    };

    state = {
        text: null,
        hasPanResponder: false
    };

    constructor(props) {
        super(props);
        this._pathsToProcess = [];
        this._paths = [];
        this._shapes = [];
        this._history = [];
        this._path = null;
        this._handle = null;
        this._screenScale = Platform.OS === "ios" ? 1 : PixelRatio.get();
        this._offset = { x: 0, y: 0 };
        this._size = { width: 0, height: 0 };
        this._initialized = false;

        this.state = {
            text: ImageEditor.processText(props.text ? props.text.map((t) => Object.assign({}, t)) : null),
            hasPanResponder: false
        };
    }

    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.text) {
            return {
                text: ImageEditor.processText(nextProps.text ? nextProps.text.map((t) => Object.assign({}, t)) : null)
            };
        } else {
            return null;
        }
    }

    static processText(text) {
        text && text.forEach((t) => (t.fontColor = processColor(t.fontColor)));
        return text;
    }

    componentDidUpdate(prevProps, prevState) {
        if (prevState.text !== this.state.text) {
            this.setState({
                text: this.state.text
            });
        }
    }

    clear() {
        this._paths = [];
        this._path = null;
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.clear,
            []
        );
        this._shapes.forEach(shape => {
            this.deleteShapeById(shape.id);
        });
        this._shapes = [];
    }

    lastAdded() {
        if (this._history.length > 0) {
            return this._history.pop();
        } else {
            return null;
        }
    }

    undo() {
        let _lastAdded = this.lastAdded();
        if (_lastAdded && _lastAdded.type == PATH) {
            let data = this._paths.find(x => x.path.id == _lastAdded.id);
            if (data && data.path && data.path.id) {
                this.deletePath(data.path.id);
            }
        } else if (_lastAdded && _lastAdded.type == SHAPE) {
            let shape = this._shapes.find(x => x.id == _lastAdded.id);
            if (shape && shape.id) {
                this.deleteShapeById(shape.id);
            }
        }
    }

    positionSelectedEntity(x, y) {
      if (this._initialized) {
          UIManager.dispatchViewManagerCommand(
              this._handle,
              UIManager.getViewManagerConfig(RNImageEditor).Commands.positionSelectedEntity,
              [x, y]
          );
      } else {
          this._pathsToProcess.filter((p) => p.path.id === data.path.id).length === 0 &&
              this._pathsToProcess.push(data);
      }
    }

    onShapePositionUpdate(shapePositionUpdate, shapeID, transform, center) {
      this._shapes = this._shapes.map((shape) => {
        if (shape.id === shapeID) {
          shape.transform = transform;
          shape.center = center;
        }
        return shape;
      });
    }

    addPath(data) {
        if (this._initialized) {
            if (this._paths.filter((p) => p.path.id === data.path.id).length === 0) {
                this._paths.push(data);
                this._history.push({ type: PATH, id: data.path.id });
            }
            const pathData = data.path.data.map((p) => {
                const coor = p.split(",").map((pp) => parseFloat(pp).toFixed(2));
                return `${(coor[0] * this._screenScale * this._size.width) / data.size.width},${(coor[1] *
                    this._screenScale *
                    this._size.height) /
                    data.size.height}`;
            });
            UIManager.dispatchViewManagerCommand(
                this._handle,
                UIManager.getViewManagerConfig(RNImageEditor).Commands.addPath,
                [data.path.id, processColor(data.path.color), data.path.width * this._screenScale, pathData]
            );
        } else {
            this._pathsToProcess.filter((p) => p.path.id === data.path.id).length === 0 &&
                this._pathsToProcess.push(data);
        }
    }

    deletePath(id) {
        this._paths = this._paths.filter((p) => p.path.id !== id);
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.deletePath,
            [id]
        );
    }

    addShape(config) {
        if (config) {
            let id =  Math.random().toString(36).substr(2, 9);
            this._shapes.push({ id, ...config });
            this._history.push({ type: SHAPE, id: id });
            let fontSize = config.textShapeFontSize ? config.textShapeFontSize : 0;
            UIManager.dispatchViewManagerCommand(
                this._handle,
                UIManager.getViewManagerConfig(RNImageEditor).Commands.addShape,
                [id, config.shapeType, config.textShapeFontType, fontSize, config.textShapeText, config.imageShapeAsset]
            );
        }
    }

    deleteShapeById(shapeId) {
        this._shapes = this._shapes.filter((p) => p.id !== shapeId);
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.deleteShapeById,
            [shapeId]
        );
    }

    deleteSelectedShape() {
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.deleteSelectedShape,
            []
        );
    }

    unselectShape() {
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.unselectShape,
            []
        );
    }

    increaseSelectedShapeFontsize() {
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.increaseShapeFontsize,
            []
        );
    }

    decreaseSelectedShapeFontsize() {
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.decreaseShapeFontsize,
            []
        );
    }

    changeSelectedShapeText(newText) {
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.changeShapeText,
            [newText]
        );
    }

    save(imageType, transparent, folder, filename, includeImage, includeText, cropToImageSize) {
        UIManager.dispatchViewManagerCommand(
            this._handle,
            UIManager.getViewManagerConfig(RNImageEditor).Commands.save,
            [imageType, folder, filename, transparent, includeImage, includeText, cropToImageSize]
        );
    }

    getPaths() {
        return this._paths;
    }

    getBase64(imageType, transparent, includeImage, includeText, cropToImageSize, callback) {
        if (Platform.OS === "ios") {
            ImageEditorManager.transferToBase64(
                this._handle,
                imageType,
                transparent,
                includeImage,
                includeText,
                cropToImageSize,
                callback
            );
        } else {
            NativeModules.ImageEditorModule.transferToBase64(
                this._handle,
                imageType,
                transparent,
                includeImage,
                includeText,
                cropToImageSize,
                callback
            );
        }
    }

    async componentDidMount() {
        const isStoragePermissionAuthorized = await requestPermissions(
            this.props.permissionDialogTitle,
            this.props.permissionDialogMessage
        );
        this.panResponder = PanResponder.create({
            // Ask to be the responder:
            onStartShouldSetPanResponder: (evt, gestureState) => true,
            onStartShouldSetPanResponderCapture: (evt, gestureState) => true,
            onMoveShouldSetPanResponder: (evt, gestureState) => true,
            onMoveShouldSetPanResponderCapture: (evt, gestureState) => true,

            onPanResponderGrant: (evt, gestureState) => {
                if (!this.props.touchEnabled) return;
                const e = evt.nativeEvent;
                this._offset = { x: e.pageX - e.locationX, y: e.pageY - e.locationY };
                this._path = {
                    id: parseInt(Math.random() * 100000000),
                    color: this.props.strokeColor,
                    width: this.props.strokeWidth,
                    data: []
                };

                UIManager.dispatchViewManagerCommand(
                    this._handle,
                    UIManager.getViewManagerConfig(RNImageEditor).Commands.newPath,
                    [this._path.id, processColor(this._path.color), this._path.width * this._screenScale]
                );
                UIManager.dispatchViewManagerCommand(
                    this._handle,
                    UIManager.getViewManagerConfig(RNImageEditor).Commands.addPoint,
                    [
                        parseFloat((gestureState.x0 - this._offset.x).toFixed(2) * this._screenScale),
                        parseFloat((gestureState.y0 - this._offset.y).toFixed(2) * this._screenScale),
                        false
                    ]
                );
                const x = parseFloat((gestureState.x0 - this._offset.x).toFixed(2)),
                    y = parseFloat((gestureState.y0 - this._offset.y).toFixed(2));
                this._path.data.push(`${x},${y}`);
                this.props.onStrokeStart(x, y);
            },
            onPanResponderMove: (evt, gestureState) => {
                if (!this.props.touchEnabled) return;
                if (Math.abs(gestureState.dx) < 2.5 || Math.abs(gestureState.dy) < 2.5) return;
                if (this._path) {
                    const x = parseFloat(
                            (gestureState.x0 + gestureState.dx / this.props.scale - this._offset.x).toFixed(2)
                        ),
                        y = parseFloat(
                            (gestureState.y0 + gestureState.dy / this.props.scale - this._offset.y).toFixed(2)
                        );
                    UIManager.dispatchViewManagerCommand(
                        this._handle,
                        UIManager.getViewManagerConfig(RNImageEditor).Commands.addPoint,
                        [parseFloat(x * this._screenScale), parseFloat(y * this._screenScale), true]
                    );
                    this._path.data.push(`${x},${y}`);
                    this.props.onStrokeChanged(x, y);
                }
            },
            onPanResponderRelease: (evt, gestureState) => {
                if (!this.props.touchEnabled) return;
                if (this._path) {
                    this.props.onStrokeEnd({ path: this._path, size: this._size, drawer: this.props.user });
                    this._paths.push({ path: this._path, size: this._size, drawer: this.props.user });
                    this._history.push({ type: PATH, id: this._path.id})
                }
                UIManager.dispatchViewManagerCommand(
                    this._handle,
                    UIManager.getViewManagerConfig(RNImageEditor).Commands.endPath,
                    []
                );
            },

            onShouldBlockNativeResponder: (evt, gestureState) => {
                return true;
            }
        });
        this.setState({
            hasPanResponder: true
        });
    }

    render() {
        return (
            <RNImageEditor
                ref={(ref) => {
                    this._handle = ReactNative.findNodeHandle(ref);
                }}
                style={this.props.style}
                onLayout={(e) => {
                    this._size = { width: e.nativeEvent.layout.width, height: e.nativeEvent.layout.height };
                    this._initialized = true;
                    this._pathsToProcess.length > 0 && this._pathsToProcess.forEach((p) => this.addPath(p));
                }}
                {...(this.state.hasPanResponder ? this.panResponder.panHandlers : undefined)}
                {...this.panResponder?.panHandlers}
                onChange={(e) => {
                    if (e.nativeEvent.hasOwnProperty("pathsUpdate")) {
                        this.props.onPathsChange(e.nativeEvent.pathsUpdate);
                    } else if (e.nativeEvent.hasOwnProperty("success") && e.nativeEvent.hasOwnProperty("path")) {
                        this.props.onSketchSaved(e.nativeEvent.success, e.nativeEvent.path);
                    } else if (e.nativeEvent.hasOwnProperty("success")) {
                        this.props.onSketchSaved(e.nativeEvent.success);
                    } else if (e.nativeEvent.hasOwnProperty("isShapeSelected")) {
                        this.props.onShapeSelectionChanged(e.nativeEvent.isShapeSelected);
                    } else if (e.nativeEvent.hasOwnProperty("shapePositionUpdate")) {
                        this.onShapePositionUpdate(e.nativeEvent.shapePositionUpdate, e.nativeEvent.shapeID, e.nativeEvent.transform, e.nativeEvent.center);
                    }
                }}
                localSourceImage={this.props.localSourceImage}
                permissionDialogTitle={this.props.permissionDialogTitle}
                permissionDialogMessage={this.props.permissionDialogMessage}
                shapeConfiguration={{
                    shapeBorderColor: processColor(this.props.shapeConfiguration.shapeBorderColor),
                    shapeBorderStyle: this.props.shapeConfiguration.shapeBorderStyle,
                    shapeBorderStrokeWidth: this.props.shapeConfiguration.shapeBorderStrokeWidth,
                    shapeColor: processColor(this.props.strokeColor),
                    shapeStrokeWidth: this.props.strokeWidth
                }}
                text={this.state.text}
            />
        );
    }
}

ImageEditor.MAIN_BUNDLE =
    Platform.OS === "ios" ? UIManager.getViewManagerConfig(RNImageEditor).Constants.MainBundlePath : "";
ImageEditor.DOCUMENT =
    Platform.OS === "ios" ? UIManager.getViewManagerConfig(RNImageEditor).Constants.NSDocumentDirectory : "";
ImageEditor.LIBRARY =
    Platform.OS === "ios" ? UIManager.getViewManagerConfig(RNImageEditor).Constants.NSLibraryDirectory : "";
ImageEditor.CACHES =
    Platform.OS === "ios" ? UIManager.getViewManagerConfig(RNImageEditor).Constants.NSCachesDirectory : "";

module.exports = ImageEditor;
