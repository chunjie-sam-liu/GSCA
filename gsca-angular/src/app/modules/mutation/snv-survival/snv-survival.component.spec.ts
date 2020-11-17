import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { SnvSurvivalComponent } from './snv-survival.component';

describe('SnvSurvivalComponent', () => {
  let component: SnvSurvivalComponent;
  let fixture: ComponentFixture<SnvSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ SnvSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SnvSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
