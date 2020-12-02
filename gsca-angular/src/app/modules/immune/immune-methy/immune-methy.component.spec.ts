import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneMethyComponent } from './immune-methy.component';

describe('ImmuneMethyComponent', () => {
  let component: ImmuneMethyComponent;
  let fixture: ComponentFixture<ImmuneMethyComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneMethyComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneMethyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
