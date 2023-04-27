/* Demo JS */
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader';
import { RGBELoader } from 'three/examples/jsm/loaders/RGBELoader';
import { gsap } from 'gsap';
import { DoubleSide, EquirectangularRefractionMapping } from 'three';
import { AnimationUtils } from 'three';

import vertexShader from '../shaders/vertex.glsl'
import fragmentShader from '../shaders/fragments.glsl'

const hdrTextureUrl = new URL('../../public/assets/hdr.hdr', import.meta.url);
const canvas = document.querySelector('.canvas');

const renderer = new THREE.WebGLRenderer({ antialias: true, canvas: canvas });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x016);

const scene = new THREE.Scene();

const camera = new THREE.PerspectiveCamera(
  45,
  window.innerWidth / window.innerHeight,
  0.1,
  1000
);

const orbit = new OrbitControls(camera, renderer.domElement);

// Camera positioning
camera.position.set(0, 0, 100);
orbit.autoRotate = true;

renderer.outputEncoding = THREE.sRGBEncoding;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 0.9;


const loader = new THREE.TextureLoader();


var tuniform = {
  iTime:    { type: 'f', value: 0.1 },
  iResolution: {type: 'v3', value: new THREE.Vector3()},
  iChannel0:  { type: 't', value: loader.load( '/images/black.jpeg' )},
  iChannel1:  { type: 't', value: loader.load( '/images/black.jpeg' )},
};

tuniform.iResolution.value.x = window.innerWidth;
tuniform.iResolution.value.y = window.innerHeight;
// tuniform.iChannel0.value.wrapS = tuniform.iChannel0.value.wrapT = THREE.RepeatWrapping;
// tuniform.iChannel1.value.wrapS = tuniform.iChannel1.value.wrapT = THREE.RepeatWrapping;


const sphere = new THREE.Mesh(
  new THREE.PlaneGeometry(100, 100,1,1),
  new THREE.ShaderMaterial({
    uniforms: tuniform,
    vertexShader: vertexShader,
    fragmentShader: fragmentShader, 
    side:THREE.DoubleSide
  })
);

scene.add(sphere);

const clock = new THREE.Clock();

function animate() {
  tuniform.iTime.value += clock.getDelta();
  renderer.render(scene, camera);
  // orbit.update();
}

renderer.setAnimationLoop(animate);

window.addEventListener('resize', resizeEvent);

function resizeEvent() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}