import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { FeatureDiscriptionComponent } from './feature-discription.component';

describe('FeatureDiscriptionComponent', () => {
  let component: FeatureDiscriptionComponent;
  let fixture: ComponentFixture<FeatureDiscriptionComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ FeatureDiscriptionComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(FeatureDiscriptionComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
